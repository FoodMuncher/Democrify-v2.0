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
          <div class="flex flex-col items-center">
            <%= text_input f, :query,
              placeholder: "Enter Song Name",
              autocomplete: "off",
              class: "text-spotify_background_black"
            %>

            <%= if @suggested_songs do %>
              <%= unless @suggested_songs == :loading do %>

                <%!-- Suggested Songs Select --%>
                <%= select f, :track_id, @suggested_songs, class: "max-w-min text-spotify_background_black"%>

              <% else %>

                <%!-- Loading SVG --%>
                <.loading_svg />

              <% end %>
            <% end %>

            <%!-- TODO: Fix this... --%>
            <%!-- <%= error_tag f, :song_name %> --%>

            <%= submit "Save",
              phx_disable_with: "Saving...",
              class: "mt-3 py-3 px-8 rounded-full text-spotify_white font-semibold border-2 border-spotify_white
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
        <circle fill="#1ed760" stroke="#1ed760" stroke-width="2" r="15" cx="120" cy="39">
          <animate attributeName="opacity" calcMode="spline" dur="2" values="1;0;1;" keySplines=".5 0 .5 1;.5 0 .5 1" repeatCount="indefinite" begin="-.4"/>
        </circle>
        <circle fill="#1ed760" stroke="#1ed760" stroke-width="2" r="15" cx="200" cy="39">
          <animate attributeName="opacity" calcMode="spline" dur="2" values="1;0;1;" keySplines=".5 0 .5 1;.5 0 .5 1" repeatCount="indefinite" begin="-.2"/>
        </circle>
        <circle fill="#1ed760" stroke="#1ed760" stroke-width="2" r="15" cx="280" cy="39">
          <animate attributeName="opacity" calcMode="spline" dur="2" values="1;0;1;" keySplines=".5 0 .5 1;.5 0 .5 1" repeatCount="indefinite" begin="0"/>
        </circle>
      </svg>
    """
  end
end
