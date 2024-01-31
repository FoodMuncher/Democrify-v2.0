defmodule DemocrifyWeb.SongLive.FormComponent do
  use DemocrifyWeb, :live_component

  alias Democrify.{Session, Spotify}
  alias Democrify.Session.Song
  alias Democrify.Spotify.{Search, Tracks, Track}

  # =================================
  # Live View Callbacks
  # =================================

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :suggested_songs, nil)}
  end

  @impl true
  def update(%{song: song} = assigns, socket) do
    {:ok, socket
     |> assign(assigns)
     |> assign(:changeset, Session.change_song(song))}
  end

  @impl true
  def handle_event("load_suggestions", %{"song" => song_params}, socket) do
    query = song_params
    |> Map.get("query", "")
    |> String.trim()

    suggested_songs =
      unless query == "" do
        case Spotify.search_tracks(query, socket.assigns.spotify_data) do
          {:ok, %Search{tracks: %Tracks{items: tracks}}} when tracks != [] ->
            convert_tracks(tracks)

          _response ->
            nil
        end
      end

    changeset =
      socket.assigns.song
      |> Session.change_song(song_params)
      |> Map.put(:action, :validate)

    {:noreply, socket
      |> assign(:changeset, changeset)
      |> assign(:suggested_songs, suggested_songs)}
  end
  def handle_event("save", %{"song" => song_params}, socket) do
    save_song(socket, socket.assigns.action, song_params)
  end

  # =================================
  # Internal Functions
  # =================================

  defp save_song(socket, :new, song_params) do
    Session.create_song(
      song_params["track_id"],
      socket.assigns.session_id,
      socket.assigns.spotify_data,
      socket.assigns.username,
      socket.assigns.user_id
    )

    {:noreply,
     socket
     |> put_flash(:info, "Song created successfully")
     |> push_redirect(to: socket.assigns.return_to)}
  end
  defp save_song(socket, :edit, song_params) do
    Session.update_song(
      song_params["track_id"],
      socket.assigns.session_id,
      socket.assigns.spotify_data,
      socket.assigns.song
    )

    {:noreply,
     socket
     |> put_flash(:info, "Song updated successfully")
     |> push_redirect(to: socket.assigns.return_to)}
  end

  defp convert_tracks([]) do
    []
  end
  defp convert_tracks([track = %Track{} | tracks]) do
    [{"#{track.name} - #{Song.artists(track.artists)}", track.id} | convert_tracks(tracks)]
  end
end
