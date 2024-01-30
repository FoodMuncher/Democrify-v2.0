defmodule Democrify.Session.Supervisor do
  use DynamicSupervisor

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def start_worker(session_id, spotify_data) do
    spec = {Democrify.Session.Worker, %{
      session_id:   session_id,
      spotify_data: spotify_data
    }}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
