defmodule DemocrifyWeb.SongLive.SongComponent do
  use DemocrifyWeb, :live_component

  def render(assigns) do
    ~H"""
      <div id={"song-#{@song.id}"} class="flex flex-col p-4 m-2 border rounded-lg">
        <div class="flex flex-row pb-2">
          <div class="pr-2">
            <img src={@song.image_url} alt="alternatetext" class="rounded-full h-20">
          </div>
          <div>
          </div>
          <div>
            <b><%= @song.username %>'s Choice</b>
            <br>
            <%= @song.name %> - <%= @song.artists %>
          </div>
        </div>
        <div class="grid grid-cols-3 text-center">
          <a href="#" phx-click="vote" phx-target={@myself}>
            <p>Votes: <%= @song.votes %></p>
          </a>
          <div>
            <%= live_patch to: ~p"/session/#{@song.id}/edit" do %>
              <p>edit</p>
            <% end %>
          </div>
          <div>
            <%= link to: "#", phx_click: "delete", phx_value_id: @song.id do %>
              <p>delete</p>
            <% end %>
          </div>
        </div>
      </div>
    """
  end

  def handle_event("vote", _, socket) do
    Democrify.Session.inc_votes(socket.assigns.song, socket.assigns.session_id)
    {:noreply, socket}
  end
end
