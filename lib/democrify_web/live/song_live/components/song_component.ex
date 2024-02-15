defmodule DemocrifyWeb.SongLive.Component.Song do
  use DemocrifyWeb, :live_component

  alias Democrify.Session

  # =================================
  # Render Function
  # =================================

  @impl true
  def render(assigns) do
    ~H"""
      <div id={"song-#{@song.id}"} class="flex flex-col p-4 m-2 rounded-lg bg-spotify_elevated_black w-full">

        <%!-- Top Information Row --%>

        <div class="flex flex-row pb-2">

          <%!-- Song Image --%>

          <div class="mr-2 flex-none">
            <img src={@song.image_url} alt="Missing Image" class="h-20">
          </div>

          <div>

            <%!-- Username --%>

            <b><%= @song.username %>'s Choice</b>
            <br>

            <%!-- Song/Artist Name --%>

            <%= @song.name %> - <%= @song.artists %>
          </div>

          <div class="ml-auto">
            <img src="images/Spotify_Logo.png" class="h-7"/>
          </div>
        </div>

        <%!-- Bottom Button Row --%>

        <div class="grid grid-cols-3 text-center">

          <%!-- Vote Button --%>

          <.vote_button
            voted={MapSet.member?(@song.user_votes, @user_id)}
            myself={@myself}
            user_id={@user_id}
            session_id={@session_id}
            vote_count={@song.vote_count}
          />

          <%!-- Edit Button --%>

          <.edit_button
            song_id={@song.id}
            users_choice={@song.user_id == @user_id}
          />

          <%!-- Delete Button --%>

          <.delete_button
            song_id={@song.id}
            users_choice={@song.user_id == @user_id}
          />
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
  def handle_event("un-vote", %{"user_id" => user_id, "session_id" => session_id}, socket) do
    Session.decrement_vote(socket.assigns.song, user_id, session_id)
    {:noreply, socket}
  end

  # =================================
  # Internal Functions
  # =================================

  defp vote_button(assigns) do
    ~H"""
      <a
        href="#"
        phx-click={vote_event(@voted)}
        phx-target={@myself}
        phx-value-user_id={@user_id}
        phx-value-session_id={@session_id}
      >
        <p><.icon name={vote_icon(@voted)} class={"#{vote_hover(@voted)}"}/> <%= @vote_count %></p>
      </a>
    """
  end

  defp vote_event(true),  do: "un-vote"
  defp vote_event(false), do: "vote"

  defp vote_icon(true),  do: "hero-heart-solid"
  defp vote_icon(false), do: "hero-heart"

  defp vote_hover(true),  do: ""
  defp vote_hover(false), do: "hover:bg-spotify_subdued"

  defp edit_button(assigns) do
    ~H"""
    <div>
      <%= if @users_choice do %>
        <%= live_patch to: ~p"/session/#{@song_id}/edit" do %>
          <p class="text-spotify_subdued hover:text-spotify_white">edit</p>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp delete_button(assigns) do
    ~H"""
    <div>
      <%= if @users_choice do %>
        <%= link to: "#", phx_click: "delete", phx_value_id: @song_id do %>
          <p class="text-spotify_subdued hover:text-spotify_white">delete</p>
        <% end %>
      <% end %>
    </div>
    """
  end
end
