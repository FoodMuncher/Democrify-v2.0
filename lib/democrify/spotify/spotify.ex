defmodule Democrify.Spotify do
  @moduledoc """
  Module for handling any Spotify API interactions
  """

  alias Democrify.Spotify.{Tokens, Track, Search, Status, Profile}

  require Logger

  @redirect_base_url Application.compile_env!(:democrify, [__MODULE__, :redirect_base_url])

  @redirect_uri "http://#{@redirect_base_url}/callback"
  @scope "user-read-private user-read-email user-read-playback-state user-modify-playback-state"
  @client_id "4ccc8676aaf54c94a6400ce027c1c93e"
  @client_secret "7a60fbf860574f59a73702e27e7265ff"

  @type t() :: %__MODULE__{
    user_id:       String.t(),
    expiry_time:   DateTime.t(),
    access_token:  String.t(),
    refresh_token: String.t()
  }

  defstruct [
    :user_id,
    :expiry_time,
    :access_token,
    :refresh_token
  ]

  # ===========================================================
  #  Access Token Functions
  # ===========================================================

  @doc """
    Subscribes to the given user id's PubSub topic for access token updates.
  """
  @spec subscribe(t()) :: :ok | {:error, term}
  def subscribe(%__MODULE__{user_id: user_id}) do
    Phoenix.PubSub.subscribe(Democrify.PubSub, "access_token:#{user_id}")
  end

  @doc """
    Returns the authorize URL for spotify, with a different callback depending on the type of login.
  """
  @spec authorize_url(String.t()) :: String.t()
  def authorize_url(type) do
    "https://accounts.spotify.com/authorize/?response_type=code&client_id=#{@client_id}&scope=#{@scope}&redirect_uri=#{@redirect_uri}/#{type}"
  end

  @doc """
    Calls the second stage of the Spotify auth to get the access token
  """
  @spec get_authorisation_tokens(String.t(), String.t()) :: Tokens.t()
  def get_authorisation_tokens(code, type) do
    request_body = {:form, [
      code:         code,
      grant_type:   "authorization_code",
      redirect_uri: "#{@redirect_uri}/#{type}"
    ]}

    "https://accounts.spotify.com/api/token"
    |> HTTPoison.post!(request_body, token_header())
    |> Tokens.constructor()
  end

  @doc """
    Using the refresh token, gets a new access token.
    # TODO: Does this need to be exported?
  """
  @spec refresh_token(t()) :: Tokens.t()
  def refresh_token(%__MODULE__{refresh_token: refresh_token}) do
    request_body = {:form, [
      grant_type:    "refresh_token",
      refresh_token: refresh_token
    ]}

    "https://accounts.spotify.com/api/token"
    |> HTTPoison.post!(request_body, token_header())
    |> Tokens.constructor()
  end

  # ===========================================================
  #  API Functions
  # ===========================================================

  @doc """
    Return users information.
    TODO: currently used when obtaining the auth token, so don't need to add refreshing atm.
  """
  @spec get_user_information(String.t()) :: Profile.t()
  def get_user_information(access_token) do
    "https://api.spotify.com/v1/me"
    |> HTTPoison.get!(auth_header(access_token))
    |> Profile.constructor()
  end

  @doc """
    Returns
  """
  @spec get_track(String.t(), t()) :: {:ok, Track.t()} | {:error, String.t()}
  def get_track(track_id, spotify_data = %__MODULE__{}) do
    "https://api.spotify.com/v1/tracks/#{track_id}"
    |> URI.encode()
    |> HTTPoison.get(auth_header(spotify_data))
    |> case do
      {:ok, %HTTPoison.Response{status_code: code} = response} when code in [200, 204] ->
        {:ok, Track.constructor(response)}

      response ->
        Logger.error("Failed to get track. Response: #{inspect response}")
        {:error, "Failed to get track for #{track_id}."}
    end
  end

  @doc """
    Gets the top 10 tracks which match the given query.
  """
  @spec search_tracks(String.t(), t()) :: {:ok, Search.t()} | {:error, String.t()}
  def search_tracks(query, spotify_data) do
    "https://api.spotify.com/v1/search?q=#{query}&type=track&limit=10"
    |> URI.encode()
    |> HTTPoison.get(auth_header(spotify_data))
    |> case do
      {:ok, %HTTPoison.Response{status_code: code} = response} when code in [200, 204] ->
        {:ok, Search.constructor(response)}

      response ->
        Logger.error("Failed to get search for #{query}. Response: #{inspect response}")
        {:error, "Failed to get search for #{query}."}
    end
  end

  @doc """
    Fetches the spotify player status
  """
  @spec get_player_status(t()) :: {:ok, Status.t() | nil} | {:error, String.t()}
  def get_player_status(spotify_data = %__MODULE__{}) do
    "https://api.spotify.com/v1/me/player"
    |> HTTPoison.get(auth_header(spotify_data))
    |> case do
      {:ok, %HTTPoison.Response{status_code: code} = response} when code in [200, 204] ->
        {:ok, Status.constructor(response)}

      response ->
        Logger.error("Failed to get status of player. Response: #{inspect response}")
        {:error, "Failed to get status of player."}
    end
  end

  @doc """
    Adds the given song as next in the spotify queue.
    TODO: Improve spec
  """
  @spec add_song_to_queue(String.t(), t()) :: any()
  def add_song_to_queue(track_uri, spotify_data) do
    Logger.debug("Added Track: #{track_uri} to the Queue")
    "https://api.spotify.com/v1/me/player/queue?uri=#{track_uri}"
    |> URI.encode()
    |> HTTPoison.post("", auth_header(spotify_data))
    |> case do
      {:ok, %HTTPoison.Response{status_code: code}} when code in [200, 204] ->
        :ok

      response ->
        Logger.error("Failed to add track #{track_uri} to the spotify queue. Response: #{inspect response}")
        :error
    end
  end

  # ===========================================================
  #  Internal Functions
  # ===========================================================

  defp get_access_token(spotify_data = %__MODULE__{}) do
    unless DateTime.compare(DateTime.utc_now(), spotify_data.expiry_time) == :lt do
      Logger.info("Refreshing Token for #{inspect spotify_data}")

      %Tokens{
        expires_in:   expires_in,
        access_token: access_token
      } = refresh_token(spotify_data)

      broadcast(%__MODULE__{spotify_data |
        expiry_time:  DateTime.add(DateTime.utc_now(), expires_in),
        access_token: access_token
      })

      access_token
    else
      spotify_data.access_token
    end
  end

  defp token_header() do
    [
      Authorization:  "Basic #{Base.encode64("#{@client_id}:#{@client_secret}")}",
      "Content-Type": "application/x-www-form-urlencoded"
    ]
  end

  defp auth_header(spotify_data = %__MODULE__{}) do
    [Authorization: "Bearer #{get_access_token(spotify_data)}"]
  end
  defp auth_header(access_token) do
    [Authorization: "Bearer #{access_token}"]
  end

  defp broadcast(spotify_data = %__MODULE__{}) do
    Phoenix.PubSub.broadcast(Democrify.PubSub, "access_token:#{spotify_data.user_id}", {:updated_spotify_data, spotify_data})
  end
end
