defmodule DemocrifyWeb.SongLive.Component.Form do
  use DemocrifyWeb, :live_component

  # =================================
  # Render
  # =================================

  def render(assigns) do
    ~H"""
      <div class="flex flex-col items-center">
        <h2 class="font-bold text-2xl pb-2"><%= @title %></h2>

        <.form
          :let={f}
          for={%{}}
          id="song-form"
          phx-change="add_song_query"
          phx-submit="save">
          <div class="flex flex-col items-center gap-y-3">
            <%= text_input f, :query,
              class: "bg-spotify_elevated_black text-spotify_white rounded-full border-0 font-semibold
              focus:border-spotify_white focus:outline focus:ring-0 focus:outline-spotify_white
              placeholder-spotify_subdued focus:placeholder-spotify_white hover:placeholder-spotify_white",
              placeholder: "Enter Song Name",
              autocomplete: "off"
            %>

            <%= if @suggested_songs do %>
              <%= unless suggested_songs_loading?(@suggested_songs) do %>

                <%!-- Suggested Songs Select --%>
                <%= select f, :track_id, @suggested_songs,
                  class: "bg-spotify_elevated_black text-spotify_white rounded-full border-0 font-semibold
                  focus:border-spotify_white focus:outline focus:ring-0 focus:outline-spotify_white w-full
                  placeholder-spotify_subdued focus:placeholder-spotify_white hover:placeholder-spotify_white"
                %>

              <% else %>

                <%!-- Loading SVG --%>
                <.loading_svg />

              <% end %>
            <% end %>

            <%!-- TODO: Fix this... --%>
            <%!-- <%= error_tag f, :song_name %> --%>

            <%= submit "Save",
              disabled: suggested_songs_loading?(@suggested_songs),
              phx_disable_with: "Saving...",
              class: "py-2 px-6 rounded-full text-spotify_white font-semibold border-2 border-spotify_white
              bg-spotify_background_black text-spotify_background_black text-sm
              hover:text-spotify_background_black hover:bg-spotify_white"
            %>

          </div>
        </.form>
      </div>
    """
  end


  # =================================
  # Live View Components
  # =================================

  defp loading_svg(assigns) do
    ~H"""
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 78">
        <circle fill="#1DB954" stroke="#1DB954" stroke-width="2" r="15" cx="120" cy="39">
          <animate attributeName="opacity" calcMode="spline" dur="2" values="1;0;1;" keySplines=".5 0 .5 1;.5 0 .5 1" repeatCount="indefinite" begin="-.4"/>
        </circle>
        <circle fill="#1DB954" stroke="#1DB954" stroke-width="2" r="15" cx="200" cy="39">
          <animate attributeName="opacity" calcMode="spline" dur="2" values="1;0;1;" keySplines=".5 0 .5 1;.5 0 .5 1" repeatCount="indefinite" begin="-.2"/>
        </circle>
        <circle fill="#1DB954" stroke="#1DB954" stroke-width="2" r="15" cx="280" cy="39">
          <animate attributeName="opacity" calcMode="spline" dur="2" values="1;0;1;" keySplines=".5 0 .5 1;.5 0 .5 1" repeatCount="indefinite" begin="0"/>
        </circle>
      </svg>
    """
  end

  defp suggested_songs_loading?(:loading), do: true
  defp suggested_songs_loading?(_songs),   do: false
end
