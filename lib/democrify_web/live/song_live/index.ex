defmodule DemocrifyWeb.SongLive.Index do
  require Logger
  use DemocrifyWeb, :live_view

  alias Democrify.{Session, Spotify}
  alias Democrify.Session.Song
  alias Democrify.Spotify.{Search, Tracks, Track, Profile}

  @check_query_wait 750 # 3/4 of a second.

  # =================================
  # Live View Callbacks
  # =================================

  @impl true
  def mount(_params, session, socket) do
    session_id = session["session_id"]

    if Session.exists?(session_id) do
      spotify_data = session["spotify_data"]

      socket = if connected?(socket) do
        Session.subscribe(session_id)
        Spotify.subscribe(spotify_data)
        assign(socket, :session, Session.list_session(session_id))
      else
        assign(socket, :session, [])
      end

      # TODO: Safer handling here....
      profile = %Profile{} = session["user"]

      {:ok,
       socket
       |> assign(:user_id,        profile.id)
       |> assign(:username,       profile.display_name)
       |> assign(:session_id,     session_id)
       |> assign(:spotify_data,   spotify_data)}
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket
      |> assign(:session_id,      socket.assigns.session_id)
      |> assign(:action,           socket.assigns.live_action)
      |> assign(:query,           "")
      |> assign(:suggested_songs, nil)
      |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    session_id = socket.assigns.session_id

    ## TODO: Potential improvement, delete handles ID and song, saves fetching and deleting...
    songs =
      Session.get_song!(id, session_id)
      |> Session.delete_song(session_id)

    {:noreply, assign(socket, :session, songs)}
  end
  def handle_event("add_song_query", %{"query" => query}, socket) do
    query = String.trim(query)

    Process.send_after(self(), {:check_query, query}, @check_query_wait)

    {:noreply, socket
    |> assign(:query,           query)
    |> assign(:suggested_songs, loading?(query))}

  end
  def handle_event("save", %{"track_id" => track_id}, socket) do
    {:noreply, save_song(socket, socket.assigns.action, track_id)}
  end
  def handle_event("save", _params, socket) do
    {:noreply, put_flash(socket, :error, "No song selectd")}
  end

  @impl true
  def handle_info({:songs_changed, songs}, socket) do
    {:noreply, assign(socket, :session, songs)}
  end
  def handle_info({:updated_spotify_data, spotify_data}, socket) do
    Logger.info("Index Live View #{socket.assigns.session_id} received new spotify_data")
    # TODO: Add spotify_data to the session, if you refresh te page after the token has
    #       refreshed it'll pull old token from the session.
    {:noreply, assign(socket, :spotify_data, spotify_data)}
  end
  def handle_info({:check_query, query}, socket = %{assigns: %{query: query}}) do
    {:noreply, assign(socket, :suggested_songs, get_suggested_songs(query, socket.assigns.spotify_data))}
  end
  def handle_info({:check_query, _old_query}, socket) do
    {:noreply, socket}
  end

  # =================================
  # Internal Functions
  # =================================

  defp apply_action(socket, :edit, %{"id" => song_id}) do
    socket
    |> assign(:page_title, "Edit Song")
    |> assign(:song,       Session.get_song!(song_id, socket.assigns.session_id))
  end
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add Song")
    |> assign(:song,       %Song{})
  end
  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Session")
    |> assign(:song,       nil)
  end

  defp loading?(""),    do: nil
  defp loading?(_query), do: :loading

  defp get_suggested_songs("", _spotify_data), do: nil
  defp get_suggested_songs(query, spotify_data) do
    case Spotify.search_tracks(query, spotify_data) do
      {:ok, %Search{tracks: %Tracks{items: tracks}}} when tracks != [] ->
        convert_tracks(tracks)

      _response ->
        nil
    end
  end

  defp save_song(socket, :new, track_id) do
    Session.create_song(
      track_id,
      socket.assigns.session_id,
      socket.assigns.spotify_data,
      socket.assigns.username,
      socket.assigns.user_id
    )

    socket
    |> put_flash(:info, "Song created successfully")
    |> push_redirect(to: ~p"/session")
  end
  defp save_song(socket, :edit, track_id) do
    Session.update_song(
      track_id,
      socket.assigns.session_id,
      socket.assigns.spotify_data,
      socket.assigns.song
    )

    socket
    |> put_flash(:info, "Song updated successfully")
    |> push_redirect(to: ~p"/session")
  end

  defp convert_tracks([]), do: []
  defp convert_tracks([track = %Track{} | tracks]) do
    [{"#{track.name} - #{Song.artists(track.artists)}", track.id} | convert_tracks(tracks)]
  end
end
