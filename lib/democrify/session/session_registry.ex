defmodule Democrify.Session.Registry do
  use GenServer

  # ===========================================================
  # API functions
  # ===========================================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__] ++ opts)
  end

  def create(session_id) do
    GenServer.call(__MODULE__, {:create, session_id})
  end

  def lookup!(session_id) do
    [{^session_id, pid}] = :ets.lookup(__MODULE__, session_id)
    pid
  end

  def lookup(session_id) do
    case :ets.lookup(__MODULE__, session_id) do
      [{^session_id, pid}] ->
        {:ok, pid}

      [] ->
        {:error, :notfound}
    end
  end

  def delete(session_id) do
    :ets.delete(__MODULE__, session_id)
  end

  # ===========================================================
  # Callback Functions
  # ===========================================================

  @impl true
  def init(_opts) do
    :ets.new(__MODULE__, [:public, :named_table, read_concurrency: true])
    {:ok, []}
  end

  @impl true
  def handle_call({:create, session_id}, _from, state) do
    worker_pid =
      case :ets.lookup(__MODULE__, session_id) do
        [{^session_id, pid}] ->
          pid

        [] ->
          {:ok, pid} = Democrify.Session.Supervisor.start_worker(session_id)
          :ets.insert_new(__MODULE__, {session_id, pid})
          pid
      end

    {:reply, worker_pid, state}
  end
end
