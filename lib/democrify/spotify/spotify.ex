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

  # ===========================================================
  #  API Functions
  # ===========================================================

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
  """
  @spec refresh_token(String.t()) :: Tokens.t()
  def refresh_token(refresh_token) do
    request_body = {:form, [
      grant_type:    "refresh_token",
      refresh_token: refresh_token
    ]}

    "https://accounts.spotify.com/api/token"
    |> HTTPoison.post!(request_body, token_header())
    |> Tokens.constructor()
  end

  def get_user_information(access_token) do
    response =
      HTTPoison.get!("https://api.spotify.com/v1/me",
        auth_header(access_token)
      )

    Profile.constructor(response)
  end

  def get_track(track_id, access_token) do
    response =
      HTTPoison.get!("https://api.spotify.com/v1/tracks/#{track_id}",
        auth_header(access_token)
      )

    Track.constructor(response)
  end

  def search_tracks(query, access_token) do
    response =
      HTTPoison.get!(
        URI.encode("https://api.spotify.com/v1/search?q=#{query}&type=track&limit=10"),
        auth_header(access_token)
      )

    Search.constructor(response)
  end

  @doc """
    Fetches the spotify player status
  """
  @spec get_player_status(String.t(), String.t(), boolean()) :: {Status.t() | nil, String.t()}
  def get_player_status(access_token, refresh_token, refreshed? \\ false) do
    "https://api.spotify.com/v1/me/player"
    |> HTTPoison.get!(auth_header(access_token))
    |> case do
      %HTTPoison.Response{status_code: code} = response when code in [200, 204] ->
        {Status.constructor(response), access_token}

      %HTTPoison.Response{status_code: 401} when not refreshed? ->
        # TODO: Check that once we remove the Session Data ETS, if we kill
        # the session player after it has refreshed, it is able to get another access token.
        Logger.info("Refreshing Token!!!!!!!!!!!!!")
        # TODO: Better handle this returns calls correctly
        %Tokens{access_token: access_token} = refresh_token(refresh_token)

        get_player_status(access_token, refresh_token)

      response ->
        Logger.error("Failed to get status of player. Response: #{inspect response}")
        {nil, access_token}
    end
  end

  def add_song_to_queue(track_uri, access_token) do
    Logger.debug("Added Track: #{track_uri} to the Queue")

    HTTPoison.post!(
      URI.encode("https://api.spotify.com/v1/me/player/queue?uri=#{track_uri}"),
      "",
      auth_header(access_token)
    )
  end

  # ===========================================================
  #  Internal Functions
  # ===========================================================

  defp token_header() do
    [
      Authorization:  "Basic #{Base.encode64("#{@client_id}:#{@client_secret}")}",
      "Content-Type": "application/x-www-form-urlencoded"
    ]
  end

  defp auth_header(access_token) do
    [Authorization: "Bearer #{access_token}"]
  end
end
