defmodule Democrify.Session.Player do
  use GenServer, restart: :temporary

  require Logger

  alias Democrify.Spotify
  alias Democrify.Spotify.{Status, Track}
  alias Democrify.Session
  alias Democrify.Session.{Song, Registry}
  alias Democrify.Session.Worker, as: SessionWorker

  defstruct [
    :session_id,
    :queued_song,
    :current_song,
    :spotify_data
  ]

  @type state() :: %__MODULE__{
    session_id:   String.t(),
    queued_song:  Song.t(),
    current_song: Song.t(),
    spotify_data: Spotify.t()
  }

  # ===========================================================
  #  Exported Functions
  # ===========================================================

  @doc """
    Starts a session player.
  """
  @spec start_link(String.t(), Spotify.t()) :: GenServer.on_start()
  def start_link(session_id, spotify_data) do
    GenServer.start_link(__MODULE__, {session_id, spotify_data})
  end

  # ===========================================================
  #  Callback Functions
  # ===========================================================

  @impl true
  def init({session_id, spotify_data}) do
    Spotify.subscribe(spotify_data)
    poll_status()

    {:ok, %__MODULE__{
      session_id:   session_id,
      spotify_data: spotify_data
    }}
  end

  @impl true
  def handle_info(:check_status, state = %__MODULE__{}) do
    state = case Spotify.get_player_status(state.spotify_data) do
      {:ok, status = %Status{item: track = %Track{}}} ->
        if is_current_song(status, state) and not reached_end_of_queue?(status) do
          state = handle_song_statuses(track, state)

          if track.duration_ms - status.progress_ms < 2500 do
            queue_next_song(state)
          else
            state
          end
        else
          # Either:
          # * Spotify is playing a song which isn't in the queue.
          # * We have a spotify session, but democrify hasn't played any songs yet.
          # * There were no more songs in the queue and the current song finished.

          play_next_song(state)
        end

      # No spotify session currently.
      {:ok, nil} ->
        state

      # Failed to get spotify session.
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

  defp play_next_song(state = %__MODULE__{}) do
    song = Registry.lookup!(state.session_id)
    |> SessionWorker.fetch_top_track()

    if song do
      case Spotify.play_song(song, state.spotify_data) do
        :ok ->

          Session.delete_song(song, state.session_id)

          %__MODULE__{state |
            current_song: song,
            queued_song:  nil
          }

        :error ->
          state
      end
    else
      state
    end
  end

  # This is for when we queue a track, we want to know when it has started playing.
  defp handle_song_statuses(%Track{id: same_id}, state = %__MODULE__{queued_song: %Song{track_id: same_id}}) do
    %__MODULE__{state |
      current_song: state.queued_song,
      queued_song:  nil
    }
  end
  defp handle_song_statuses(%Track{}, state = %__MODULE__{}), do: state

  defp queue_next_song(state = %__MODULE__{queued_song: nil, spotify_data: spotify_data = %Spotify{}}) do
    song = Registry.lookup!(state.session_id)
    |> SessionWorker.fetch_top_track()

    if song do
      Spotify.add_song_to_queue(song, spotify_data)

      Session.delete_song(song, state.session_id)

      %{state | queued_song: song}
    else
      state
    end
  end
  defp queue_next_song(state = %__MODULE__{}), do: state

  defp is_current_song(%Status{item: %Track{id: id}}, %__MODULE__{current_song: %Song{track_id: id}}), do: true
  defp is_current_song(%Status{}, %__MODULE__{}),                                                      do: false

  defp reached_end_of_queue?(%Status{progress_ms: 0, is_playing: false}), do: true
  defp reached_end_of_queue?(%Status{item: %Track{}}),                    do: false
end
