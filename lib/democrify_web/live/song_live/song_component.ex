defmodule DemocrifyWeb.SongLive.SongComponent do
  use DemocrifyWeb, :live_component

  def render(assigns) do
    ~H"""
      <div id={"song-#{@song.id}"} class="song">
        <div class="row">
          <div class="column column-20">
            <img src={@song.image_url} alt="alternatetext">
          </div>
          <div class="column column-70 song-name">
            <b><%= @song.username %></b>
            <br/>
            <%= @song.name %> - <%= @song.artists %>
          </div>
        </div>

        <div class="row">
          <div class="column">
          <a href="#" phx-click="vote" phx-target={@myself}>
            <p>Votes: <%= @song.votes %></p>
          </a>
          </div>
          <div class="row">
            <%= live_patch to: ~p"/session/#{@song.id}/edit" do %>
              <p>edit</p>
            <% end %>
            &nbsp
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
