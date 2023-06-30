defmodule DemocrifyWeb.SongLive.Index do
  use DemocrifyWeb, :live_view

  alias Democrify.Session
  alias Democrify.Session.Song

  @impl true
  def mount(_params, session, socket) do
    session_id = session["session_id"]

    if session_id != nil && Session.exists?(session_id) do
      if connected?(socket), do: Session.subscribe(session_id)

      {:ok,
       socket
       |> assign(:session, Session.list_session(session_id))
       |> assign(:session_id, session_id)
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

  defp apply_action(socket, :edit, %{"id" => song_id}) do
    socket
    |> assign(:page_title, "Edit Song")
    |> assign(:song, Session.get_song!(song_id, socket.assigns.session_id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Song")
    |> assign(:song, %Song{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Session")
    |> assign(:song, nil)
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
end
