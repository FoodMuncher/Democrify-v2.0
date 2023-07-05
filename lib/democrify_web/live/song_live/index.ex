defmodule DemocrifyWeb.SongLive.Index do
  require Logger
  use DemocrifyWeb, :live_view

  alias Democrify.Session
  alias Democrify.Session.Song
  alias Democrify.Spotify.Profile

  # =================================
  # Live View Callbacks
  # =================================

  @impl true
  def mount(_params, session, socket) do
    session_id = session["session_id"]

    if session_id != nil && Session.exists?(session_id) do
      if connected?(socket), do: Session.subscribe(session_id)

      # TODO: Safer handling here....
      profile = %Profile{} = session["user"]

      {:ok,
       socket
       |> assign(:user_id,      profile.id)
       |> assign(:username,     profile.display_name)
       |> assign(:session,      Session.list_session(session_id))
       |> assign(:session_id,   session_id)
       |> assign(:access_token, session["access_token"])}
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:session_id, socket.assigns.session_id)
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

  @impl true
  def handle_info({:songs_changed, songs}, socket) do
    {:noreply, assign(socket, :session, songs)}
  end

  # =================================
  # Internal Functions
  # =================================

  defp apply_action(socket, :edit, %{"id" => song_id}) do
    socket
    |> assign(:page_title, "Edit Song")
    |> assign(:song, Session.get_song!(song_id, socket.assigns.session_id))
  end
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add Song")
    |> assign(:song, %Song{})
  end
  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Session")
    |> assign(:song, nil)
  end
end
