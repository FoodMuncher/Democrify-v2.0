defmodule DemocrifyWeb.SongLive.FormComponent do
  use DemocrifyWeb, :live_component

  alias Democrify.{Session, Spotify}
  alias Democrify.Session.Song

  # =================================
  # Live View Callbacks
  # =================================

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :suggested_songs, nil)}
  end

  @impl true
  def update(%{song: song} = assigns, socket) do
    changeset = Session.change_song(song)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"song" => song_params}, socket) do
    query = song_params["query"]

    suggested_songs =
      if query && query != "" do
        search = Spotify.search_tracks(query, socket.assigns.access_token)
        tracks = search.tracks.items

        if tracks != [] do
          convert_tracks(tracks)
        end
      end

    changeset =
      socket.assigns.song
      |> Session.change_song(song_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:suggested_songs, suggested_songs)

    {:noreply, assign(socket, :changeset, changeset)}
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
      socket.assigns.access_token,
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
      socket.assigns.access_token,
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
  defp convert_tracks([track | tracks]) do
    [{"#{track.name} - #{Song.artists(track.artists)}", track.id} | convert_tracks(tracks)]
  end
end
