defmodule Democrify.Session.Registry do
  use GenServer

  alias :ets, as: ETS
  alias Democrify.Session.Data, as: SessionData

  # ===========================================================
  # API functions
  # ===========================================================

  @doc """
    Starts the Session Registry.
  """
  @spec start_link(List.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__] ++ opts)
  end

  @doc """
    Creates a new session and adds it to the registry
  """
  @spec create(String.t(), String.t()) :: pid()
  def create(session_id, access_token) do
    GenServer.call(__MODULE__, {:create, session_id, access_token})
  end

  @doc """
    Returns the Session Worker pid for the session id, breaks if it isn't present.
  """
  @spec lookup!(String.t()) :: pid()
  def lookup!(session_id) do
    [{^session_id, pid}] = ETS.lookup(__MODULE__, session_id)
    pid
  end

  @doc """
    Returns the Session Worker pid for the session id.
  """
  @spec lookup!(String.t()) :: {:ok, pid()} | {:error, :notfound}
  def lookup(session_id) do
    case ETS.lookup(__MODULE__, session_id) do
      [{^session_id, pid}] ->
        {:ok, pid}

      [] ->
        {:error, :notfound}
    end
  end

  @doc """
    removes the Session Worker pid for the session id from the registry.
  """
  @spec delete(String.t()) :: true
  def delete(session_id) do
    ETS.delete(__MODULE__, session_id)
  end

  # ===========================================================
  # Callback Functions
  # ===========================================================

  @impl true
  def init(_opts) do
    ETS.new(__MODULE__, [:public, :named_table, read_concurrency: true])
    {:ok, []}
  end

  @impl true
  def handle_call({:create, session_id, access_token}, _from, state) do
    worker_pid =
      case ETS.lookup(__MODULE__, session_id) do
        [{^session_id, pid}] ->
          pid

        [] ->
          {:ok, pid} = Democrify.Session.Supervisor.start_worker(session_id)
          ETS.insert_new(__MODULE__, {session_id, pid})
          SessionData.add(session_id, access_token)
          pid
      end

    {:reply, worker_pid, state}
  end
end
