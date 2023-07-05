defmodule Democrify.Session do
  @moduledoc """
  The Session context.
  """

  alias Democrify.Session.{Song, Registry, Worker}
  alias Democrify.Spotify

  # External Functions
  # ========================================

  def create_session do
    session_id = generate_id()
    Registry.create(session_id)
    session_id
  end

  def exists?(session_id) do
    Registry.lookup(session_id) != {:error, :notfound}
  end

  def list_session(session_id) do
    # TODO: Use actual session ID
    Registry.lookup!(session_id)
    |> Worker.fetch_all()
  end

  def inc_votes(%Song{} = song, session_id) do
    Registry.lookup!(session_id)
    |> Worker.increment(song)
    |> broadcast(session_id, :songs_changed)
  end

  def get_song!(song_id, session_id) do
    Registry.lookup!(session_id)
    |> Worker.fetch(song_id)
  end

  def create_song(track_id, session_id, access_token) do
    Registry.lookup!(session_id)
    |> Worker.add(fetch_song(track_id, access_token))
    |> broadcast(session_id, :songs_changed)
  end

  def update_song(track_id, session_id, access_token, %Song{} = song) do
    song = fetch_song(track_id, access_token, song)

    Registry.lookup!(session_id)
    |> Worker.update(%Song{song | votes: 0})
    |> broadcast(session_id, :songs_changed)
  end

  def delete_song(%Song{} = song, session_id) do
    Registry.lookup!(session_id)
    |> Worker.delete(song)
    |> broadcast(session_id, :songs_changed)
  end

  def change_song(%Song{} = song, attrs \\ %{}) do
    Song.changeset(song, attrs)
  end

  def subscribe(session_id) do
    Phoenix.PubSub.subscribe(Democrify.PubSub, "session:#{session_id}")
  end

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

  defp fetch_song(track_id, access_token) do
    fetch_song(track_id, access_token, %Song{})
  end

  defp fetch_song(track_id, access_token, song) do
    track = Spotify.get_track(track_id, access_token)

    %Song{
      song
      | name: track.name,
        artists: Song.artists(track.artists),
        image_url: hd(track.album.images).url,
        track_id: track_id,
        track_uri: track.uri
    }
  end
end
