defmodule Democrify.Session.Worker do
  use GenServer, restart: :temporary

  require Logger

  alias Democrify.Spotify
  alias Democrify.Session.Song
  alias Democrify.Session.Player, as: SessionPlayer

  # TODO: Have cleanup message or time out, which cleans up this is session if it's inactive for x amount of time...

  defstruct [
    :player_pid,
    :session_id,
    :spotify_data,
    id:      1,
    session: [],
  ]

  # =================================
  # API Functions
  # =================================

  @doc """
    Starts the Session Worker.
  """
  @spec start_link(map()) :: GenServer.on_start()
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @doc """
    Returns all the songs currently in this session..
  """
  @spec fetch_all(pid()) :: [Song.t()]
  def fetch_all(worker_pid) do
    GenServer.call(worker_pid, :fetch_all)
  end

  @doc """
    Returns the current most voted track.
  """
  @spec fetch_top_track(pid()) :: Song.t() | nil
  def fetch_top_track(worker_pid) do
    GenServer.call(worker_pid, :fetch_top_song)
  end

  @doc """
    Returns the song for the given ID or nil.
  """
  @spec fetch(pid(), integer() | String.t()) :: Song.t() | nil
  def fetch(worker_pid, song_id) when is_binary(song_id) do
    fetch(worker_pid, String.to_integer(song_id))
  end
  def fetch(worker_pid, song_id) when is_integer(song_id) do
    GenServer.call(worker_pid, {:fetch, song_id})
  end

  @doc """
    Adds the given song to the session.
  """
  @spec add(pid(), Song.t()) :: [Song.t()]
  def add(worker_pid, song) do
    GenServer.call(worker_pid, {:add, song})
  end

  @doc """
    Increments the song's votes in the session
  """
  @spec increment(pid(), String.t(), Song.t()) :: [Song.t()]
  def increment(worker_pid, user_id, %Song{id: song_id}) do
    GenServer.call(worker_pid, {:increment, user_id, song_id})
  end

  @doc """
    Decrements the song's votes in the session
  """
  @spec decrement(pid(), String.t(), Song.t()) :: [Song.t()]
  def decrement(worker_pid, user_id, %Song{id: song_id}) do
    GenServer.call(worker_pid, {:decrement, user_id, song_id})
  end

  @doc """
    Update the given song in the session.
  """
  @spec update(pid(), Song.t()) :: [Song.t()]
  def update(worker_pid, song) do
    GenServer.call(worker_pid, {:update, song})
  end

  @doc """
    Remove the song from the session.
  """
  @spec delete(pid(), integer()) :: [Song.t()]
  def delete(worker_pid, song_id) do
    GenServer.call(worker_pid, {:delete, song_id})
  end

  # =================================
  # Callback Functions
  # =================================

  @impl true
  def init(init_args) do
    Spotify.subscribe(init_args.spotify_data)

    {:ok, %__MODULE__{
      session_id:   init_args.session_id,
      spotify_data: init_args.spotify_data
    }, {:continue, nil}}
  end

  @impl true
  def handle_continue(nil, state = %__MODULE__{}) do
    Process.flag(:trap_exit, true)
    # TODO: Tidy this function call up!!!
    {:ok, player_pid} = SessionPlayer.start_link(state.session_id, state.spotify_data)
    {:noreply, %__MODULE__{state | player_pid: player_pid}}
  end

  @impl true
  def handle_call(:fetch_all, _from, state = %__MODULE__{}) do
    {:reply, strip_ids(state.session), state}
  end
  def handle_call(:fetch_top_song, _from, state = %__MODULE__{session: []}) do
    {:reply, nil, state}
  end
  def handle_call(:fetch_top_song, _from, state = %__MODULE__{session: [{_id, song} | _]}) do
    {:reply, song, state}
  end
  def handle_call({:fetch, id}, _from, state = %__MODULE__{}) do
    {^id, song} = List.keyfind(state.session, id, 0, {id, nil})
    {:reply, song, state}
  end
  def handle_call({:add, song}, _from, state = %__MODULE__{id: id}) do
    session = state.session ++ [{id, %Song{song | id: id}}]
    {:reply, strip_ids(session), %__MODULE__{state | session: session, id: id + 1}}
  end
  def handle_call({:increment, user_id, song_id}, _from, state = %__MODULE__{session: session}) do
    session =
      with {{_id, song = %Song{}}, session} <- List.keytake(session, song_id, 0),
           false                            <- MapSet.member?(song.user_votes, user_id)
      do
        song = %Song{song |
          vote_count: song.vote_count + 1,
          user_votes: MapSet.put(song.user_votes, user_id)
        }

        add_song_to_session(session, song)
      else
        # List.keytake/3 case
        nil ->
          Logger.error("Received increment for unknown Song: #{song_id} Session: #{state.session_id}")
          session

        # Mapset.member?/2 case
        true ->
          Logger.warn("User already voted for Song: #{song_id} Session: #{state.session_id} User: #{user_id}")
          session
      end

    {:reply, strip_ids(session), %__MODULE__{state | session: session}}
  end
  def handle_call({:decrement, user_id, song_id}, _from, state = %__MODULE__{session: session}) do
    session =
      with {{_id, song = %Song{}}, session} <- List.keytake(session, song_id, 0),
           true                             <- MapSet.member?(song.user_votes, user_id)
      do
        song = %Song{song |
          vote_count: song.vote_count - 1,
          user_votes: MapSet.delete(song.user_votes, user_id)
        }

        add_song_to_session(session, song)
      else
        # List.keytake/3 case
        nil ->
          Logger.error("Received decrement for unknown Song: #{song_id} Session: #{state.session_id}")
          session

        # Mapset.member?/2 case
        false ->
          Logger.warn("User hasn't voted for Song: #{song_id} Session: #{state.session_id} User: #{user_id}")
          session
      end

    {:reply, strip_ids(session), %__MODULE__{state | session: session}}
  end
  # TODO: Add test for this guy
  def handle_call({:update, song}, _from, state = %__MODULE__{}) do
    session = state.session
    |> List.keydelete(song.id, 0)
    |> Kernel.++([{song.id, song}])

    {:reply, strip_ids(session), %__MODULE__{state | session: session}}
  end
  def handle_call({:delete, song_id}, _from, state = %__MODULE__{}) do
    session = List.keydelete(state.session, song_id, 0)
    {:reply, strip_ids(session), %__MODULE__{state | session: session}}
  end

  @impl true
  def handle_info({:updated_spotify_data, spotify_data}, state = %__MODULE__{}) do
    Logger.info("Session Worker #{state.session_id} received new spotify_data")
    {:noreply, %__MODULE__{state | spotify_data: spotify_data}}
  end
  def handle_info({:EXIT, _pid, reason}, state = %__MODULE__{}) do
    Logger.error("Player Crashed, Reason: #{inspect reason}")
    {:ok, player_pid} = SessionPlayer.start_link(state.session_id, state.spotify_data)
    {:noreply, %__MODULE__{state | player_pid: player_pid}}
  end

  # =================================
  # Internal functions
  # =================================

  defp add_song_to_session([], song = %Song{}), do: [{song.id, song}]
  defp add_song_to_session([{id, song = %Song{}} | tail], new_song = %Song{}) when song.vote_count < new_song.vote_count do
    [{new_song.id, new_song}, {id, song} | tail]
  end
  defp add_song_to_session([{id, song = %Song{}} | tail], new_song = %Song{}) do
    [{id, song} | add_song_to_session(tail, new_song)]
  end

  defp strip_ids(list) do
    for {_song_id, song} <- list, do: song
  end
end
