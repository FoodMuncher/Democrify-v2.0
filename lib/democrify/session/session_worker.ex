defmodule Democrify.Session.Worker do
  use GenServer, restart: :temporary

  require Logger

  alias Democrify.Session.Song

  # TODO: Have cleanup message or time out, which cleans up this is session if it's inactive for x amount of time...

  # =================================
  # API Functions
  # =================================

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def fetch_all(worker_pid) do
    GenServer.call(worker_pid, :fetch_all)
  end

  def fetch_top_track(worker_pid) do
    GenServer.call(worker_pid, :fetch_top_song)
  end

  def fetch(worker_pid, id) when is_binary(id) do
    fetch(worker_pid, String.to_integer(id))
  end

  def fetch(worker_pid, id) when is_integer(id) do
    GenServer.call(worker_pid, {:fetch, id})
  end

  def add(worker_pid, song) do
    GenServer.call(worker_pid, {:add, song})
  end

  def increment(worker_pid, %Song{id: id}) do
    GenServer.call(worker_pid, {:increment, id})
  end

  def update(worker_pid, song) do
    GenServer.call(worker_pid, {:update, song})
  end

  def delete(worker_pid, %Song{id: id}) do
    GenServer.call(worker_pid, {:delete, id})
  end

  # =================================
  # Callback Functions
  # =================================

  @impl true
  def init(%{session_id: session_id}) do
    send(self(), :start_player)

    {:ok,
     %{
       session: [],
       id: 1,
       player_pid: nil,
       session_id: session_id
     }}
  end

  @impl true
  def handle_call(:fetch_all, _from, state) do
    {:reply, strip_ids(state.session), state}
  end

  def handle_call(:fetch_top_song, _from, state) do
    return =
      if state.session != [] do
        {_id, song} = hd(state.session)
        song
      else
        nil
      end

    {:reply, return, state}
  end

  def handle_call({:fetch, id}, _from, state) do
    {^id, song} = List.keyfind(state.session, id, 0)
    {:reply, song, state}
  end

  def handle_call({:add, song}, _from, state) do
    session = state.session ++ [{state.id, %{song | id: state.id}}]
    {:reply, strip_ids(session), %{state | session: session, id: state.id + 1}}
  end

  def handle_call({:increment, id}, _from, %{session: session} = state) do
    case List.keytake(session, id, 0) do
      {{^id, song}, session} ->
        song = %{song | votes: song.votes + 1}
        session = increment(session, song, [])
        {:reply, strip_ids(session), %{state | session: session}}

      nil ->
        Logger.error("Received unknown update for Song: #{id}")
        {:reply, strip_ids(session), state}
    end
  end

  # TODO: Add test for this guy
  def handle_call({:update, song}, _from, state) do
    session = List.keydelete(state.session, song.id, 0)
    session = session ++ [{song.id, song}]
    {:reply, strip_ids(session), %{state | session: session}}
  end

  def handle_call({:delete, id}, _from, state) do
    session = List.keydelete(state.session, id, 0)
    {:reply, strip_ids(session), %{state | session: session}}
  end

  @impl true
  def handle_info(:start_player, state) do
    Process.flag(:trap_exit, true)
    {:ok, player_pid} = Democrify.Spotify.Player.start_link(state.session_id)
    {:noreply, %{state | player_pid: player_pid}}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.error("Player Crashed, Reason: #{inspect(reason)}")
    {:ok, player_pid} = Democrify.Spotify.Player.start_link(state.session_id)
    {:noreply, %{state | player_pid: player_pid}}
  end

  # =================================
  # Internal functions
  # =================================

  defp increment([], bumped_song, acc) do
    acc ++ [{bumped_song.id, bumped_song}]
  end

  defp increment([{id, song} | tail] = list, bumped_song, acc) do
    case song.votes < bumped_song.votes do
      false ->
        increment(tail, bumped_song, acc ++ [{id, song}])

      true ->
        acc ++ [{bumped_song.id, bumped_song}] ++ list
    end
  end

  defp strip_ids(list) do
    for {_id, song} <- list, do: song
  end
end
