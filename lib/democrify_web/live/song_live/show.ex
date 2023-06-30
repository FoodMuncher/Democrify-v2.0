defmodule DemocrifyWeb.SongLive.Show do
  use DemocrifyWeb, :live_view

  alias Democrify.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     #  TODO: Not actually sure when this is called, so just hard coded the session id to 12 for now.
     |> assign(:song, Session.get_song!(id, 12))}
  end

  defp page_title(:show), do: "Show Song"
  defp page_title(:edit), do: "Edit Song"
end
