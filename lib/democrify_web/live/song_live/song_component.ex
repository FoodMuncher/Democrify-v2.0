defmodule DemocrifyWeb.SongLive.SongComponent do
  use DemocrifyWeb, :live_component

  alias Democrify.Session

  # =================================
  # Render Function
  # =================================

  @impl true
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
          <a
            href="#"
            phx-click="vote"
            phx-target={@myself}
            phx-value-user_id={@user_id}
            phx-value-session_id={@session_id}
          >
            <p>Votes: <%= @song.vote_count %></p>
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

  # =================================
  # Event Function
  # =================================

  @impl true
  def handle_event("vote", %{"user_id" => user_id, "session_id" => session_id}, socket) do
    Session.increment_vote(socket.assigns.song, user_id, session_id)
    {:noreply, socket}
  end
end
