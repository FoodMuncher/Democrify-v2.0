defmodule DemocrifyWeb.SongLive.FormComponent do
  use DemocrifyWeb, :live_component

  alias Democrify.Session
  require Logger

  # =================================
  # Live View Callbacks
  # =================================

  @impl true
  def update(%{song: song} = assigns, socket) do
    {:ok, socket
    |> assign(assigns)
    |> assign(:changeset, Session.change_song(song))}
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
