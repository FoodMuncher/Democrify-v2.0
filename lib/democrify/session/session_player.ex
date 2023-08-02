defmodule Democrify.Spotify.Player do
  use GenServer, restart: :temporary

  # TODO: This whole module needs a tidy up!
  # TODO: change from session pid to use regoistry in event the worker dies....

  require Logger
  alias Democrify.Spotify

  defstruct [
    :session_id,
    :session_pid,
    :access_token,
    :refresh_token,
    :next_queued_song,
    :current_queued_song
  ]

  # ===========================================================
  #  Exported Functions
  # ===========================================================

  @doc """
    Starts a session player.
  """
  @spec start_link(String.t(), String.t(), String.t()) :: GenServer.on_start()
  def start_link(session_id, access_token, refresh_token) do
    GenServer.start_link(__MODULE__, {session_id, self(), access_token, refresh_token})
  end

  # ===========================================================
  #  Callback Functions
  # ===========================================================

  @impl true
  def init({session_id, session_pid, access_token, refresh_token}) do
    Process.send_after(self(), :check_status, 1000)

    {:ok, %__MODULE__{
      session_id:    session_id,
      session_pid:   session_pid,
      access_token:  access_token,
      refresh_token: refresh_token
    }}
  end

  @impl true
  def handle_info(:check_status, state = %__MODULE__{}) do
    {status, access_token} = Spotify.get_player_status(state.access_token, state.refresh_token)

    Logger.info("Status: #{inspect status}")

    # new song is
    state =
      if state.next_queued_song != nil && status.item.id == state.next_queued_song.track_id do
        %__MODULE__{state | current_queued_song: state.next_queued_song, next_queued_song: nil}
      else
        state
      end

    # TODO: check that the current song is whats expected...
    state =
      if status != nil && status.item.duration_ms - status.progress_ms < 2500 do
        queue_next_song(state, access_token)
      else
        state
      end

    Process.send_after(self(), :check_status, 1000)

    {:noreply, %__MODULE__{state | access_token: access_token}}
  end

  # ===========================================================
  #  Internal Functions
  # ===========================================================

  defp queue_next_song(state = %__MODULE__{next_queued_song: nil}, _access_token), do: state
  defp queue_next_song(state = %__MODULE__{}, access_token) do
    song = Democrify.Session.Worker.fetch_top_track(state.session_pid)

    unless song == nil do
      Spotify.add_song_to_queue(song.track_uri, access_token)

      Democrify.Session.delete_song(song, state.session_id)

      %{state | next_queued_song: song}
    else
      state
    end
  end
end
