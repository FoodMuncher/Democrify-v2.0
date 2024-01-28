defmodule Democrify.Spotify.Player do
  use GenServer, restart: :temporary

  # TODO: This whole module needs a tidy up!
  # TODO: change from session pid to use registry in event the worker dies....

  require Logger

  alias Democrify.Spotify
  alias Democrify.Spotify.{Status, Track}

  defstruct [
    :session_id,
    :session_pid,
    :spotify_data,
    :next_queued_song,
    :current_queued_song
  ]

  # ===========================================================
  #  Exported Functions
  # ===========================================================

  @doc """
    Starts a session player.
  """
  @spec start_link(String.t(), Spotify.t()) :: GenServer.on_start()
  def start_link(session_id, spotify_data) do
    GenServer.start_link(__MODULE__, {session_id, self(), spotify_data})
  end

  # ===========================================================
  #  Callback Functions
  # ===========================================================

  @impl true
  def init({session_id, session_pid, spotify_data}) do
    Spotify.subscribe(spotify_data)
    poll_status()

    {:ok, %__MODULE__{
      session_id:   session_id,
      session_pid:  session_pid,
      spotify_data: spotify_data
    }}
  end

  @impl true
  def handle_info(:check_status, state = %__MODULE__{}) do
    state = case Spotify.get_player_status(state.spotify_data) do
      {:ok, status = %Status{item: track = %Track{}}} ->
        # Logger.info("Status: #{inspect status}")

        # new song is
        state =
          if state.next_queued_song && track.id == state.next_queued_song.track_id do
            %__MODULE__{state | current_queued_song: state.next_queued_song, next_queued_song: nil}
          else
            state
          end

        # Logger.info("Next Song? = #{status != nil && status.item.duration_ms - status.progress_ms < 2500}")

        # TODO: check that the current song is whats expected...
        if track.duration_ms - status.progress_ms < 2500 do
          queue_next_song(state, state.spotify_data)
        else
          state
        end

      {:ok, nil} ->
        state

      {:error, reason} ->
        Logger.error("Failed to check status as: #{reason}.")

        state
    end

    poll_status()

    {:noreply, state}
  end
  def handle_info({:updated_spotify_data, spotify_data}, state = %__MODULE__{}) do
    Logger.info("Session Player #{state.session_id} received new spotify_data")
    {:noreply, %__MODULE__{state | spotify_data: spotify_data}}
  end

  # ===========================================================
  #  Internal Functions
  # ===========================================================

  defp poll_status(), do: Process.send_after(self(), :check_status, 1000)

  defp queue_next_song(state = %__MODULE__{next_queued_song: nil}, %Spotify{}), do: state
  defp queue_next_song(state = %__MODULE__{}, spotify_data = %Spotify{}) do
    song = Democrify.Session.Worker.fetch_top_track(state.session_pid)

    Logger.error("Song: #{inspect song}")

    if song do
      Spotify.add_song_to_queue(song.track_uri, spotify_data)

      Democrify.Session.delete_song(song, state.session_id)

      %{state | next_queued_song: song}
    else
      state
    end
  end
end
