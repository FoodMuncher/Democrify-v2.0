defmodule Democrify.Session do
  @moduledoc """
  The Session context.
  TODO: specs and docs!!
  """

  require Logger

  alias Democrify.Spotify
  alias Democrify.Spotify.Track
  alias Democrify.Session.{Song, Registry, Worker}

  # ========================================
  # Exported Functions
  # ========================================

  @doc """
    Creates a new Session Worker and returns the session_id.
  """
  @spec create_session() :: String.t()
  def create_session() do
    session_id = generate_id()
    Registry.create(session_id)
    session_id
  end

  @doc """
    Checks if the session_id corresponds to a live SessionWorker.
  """
  @spec exists?(String.t()) :: boolean()
  def exists?(session_id) do
    Registry.lookup(session_id) != {:error, :notfound}
  end

  @doc """
    Returns the songs in order for the given session id.
  """
  @spec list_session(String.t()) :: [Song.t()]
  def list_session(session_id) do
    # TODO: Use actual session ID
    Registry.lookup!(session_id)
    |> Worker.fetch_all()
  end

  @doc """
    Increments the given songs vote counter, unless the user has already voted for this song.
    Returns the updated list of songs for this session.
  """
  @spec increment_vote(Song.t(), String.t(), String.t()) :: [Song.t()]
  def increment_vote(%Song{} = song, user_id, session_id) do
    Registry.lookup!(session_id)
    |> Worker.increment(user_id, song)
    |> broadcast(session_id, :songs_changed)
  end

  @doc """
    Decrements the given songs vote counter, unless the user hasn't voted for this song.
    Returns the updated list of songs for this session.
  """
  @spec decrement_vote(Song.t(), String.t(), String.t()) :: [Song.t()]
  def decrement_vote(%Song{} = song, user_id, session_id) do
    Registry.lookup!(session_id)
    |> Worker.decrement(user_id, song)
    |> broadcast(session_id, :songs_changed)
  end

  @doc """
    Returns the song corresponding to the given song id.
  """
  @spec get_song!(Integer.t(), String.t()) :: Song.t()
  def get_song!(song_id, session_id) do
    Registry.lookup!(session_id)
    |> Worker.fetch(song_id)
  end

  @doc """
    Fetches the song information from the Spotify API and adds the song to the session.
    Returns the updated list of songs for this session.
  """
  @spec create_song(String.t(), String.t(), String.t(), String.t(), String.t()) :: [Song.t()]
  def create_song(track_id, session_id, access_token, username, user_id) do
    Registry.lookup!(session_id)
    |> Worker.add(fetch_song(track_id, access_token, username, user_id))
    |> broadcast(session_id, :songs_changed)
  end

  @doc """
    Removes the given song from the session and adds the new song.
    Returns the updated list of songs for this session.
  """
  @spec update_song(String.t(), String.t(), String.t(), Song.t()) :: [Song.t()]
  def update_song(track_id, session_id, access_token, %Song{} = song) do
    song = fetch_song(track_id, access_token, song)

    Registry.lookup!(session_id)
    |> Worker.update(%Song{song | vote_count: 0})
    |> broadcast(session_id, :songs_changed)
  end

  @doc """
    Deletes the song from teh session.
    Returns the updated list of songs for this session.
  """
  @spec delete_song(Song.t(), String.t()) :: [Song.t()]
  def delete_song(%Song{} = song, session_id) do
    Registry.lookup!(session_id)
    |> Worker.delete(song)
    |> broadcast(session_id, :songs_changed)
  end

  @doc """
    TODO: Do this doc and spec...
  """
  @spec change_song(Song.t(), map()) :: any()
  def change_song(%Song{} = song, attrs \\ %{}) do
    Song.changeset(song, attrs)
  end

  @doc """
    Subscribes to the given session id's PubSub topic
  """
  @spec subscribe(String.t()) :: :ok | {:error, term}
  def subscribe(session_id) do
    Phoenix.PubSub.subscribe(Democrify.PubSub, "session:#{session_id}")
  end

  # ========================================
  # Internal Functions
  # ========================================

  defp broadcast(songs, session_id, event) do
    Phoenix.PubSub.broadcast(Democrify.PubSub, "session:#{session_id}", {event, songs})
    songs
  end

  # TODO: Maybe use some pet name dep, so it's green-dragon-fly etc
  defp generate_id do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end

  defp fetch_song(track_id, access_token, username, user_id) do
    fetch_song(track_id, access_token, %Song{
      user_id:  user_id,
      username: username
    })
  end

  defp fetch_song(track_id, access_token, song) do
    track = %Track{} = Spotify.get_track(track_id, access_token)

    %Song{song |
      name:      track.name,
      artists:   Song.artists(track.artists),
      track_id:  track_id,
      track_uri: track.uri,
      image_url: hd(track.album.images).url
    }
  end
end
