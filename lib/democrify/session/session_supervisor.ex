defmodule Democrify.Session.Supervisor do
  use DynamicSupervisor

  alias Democrify.Spotify

  # ===========================================================
  # Exported Functions
  # ===========================================================

  @doc """
    Starts the Session DynamicSupervisor
  """
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @doc """
    Starts a Session Worker under the Dynamic Supervisor
  """
  @spec start_worker(String.t(), Spotify.t()) :: DynamicSupervisor.on_start_child()
  def start_worker(session_id, spotify_data) do
    spec = {Democrify.Session.Worker, %{
      session_id:   session_id,
      spotify_data: spotify_data
    }}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  # ===========================================================
  # Callback Functions
  # ===========================================================

  @impl true
  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
