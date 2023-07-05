defmodule Democrify.Spotify.Player do
  use GenServer, restart: :temporary

  # TODO: This whole module needs a tidy up!

  alias Democrify.Spotify

  def start_link(session_id) do
    GenServer.start_link(__MODULE__, %{session_id: session_id, session_pid: self()})
  end

  def init(%{session_id: session_id, session_pid: session_pid}) do
    # TODO: better start up, race condition here on access token being added and the first status check
    Process.send_after(self(), :check_status, 1000)

    {:ok,
     %{
       session_pid: session_pid,
       session_id: session_id,
       current_queued_song: nil,
       next_queued_song: nil
     }}
  end

  def handle_info(:check_status, state) do
    # TODO: add access_token to the state if it exists
    access_token = Democrify.Session.Data.fetch!(state.session_id)

    status = Spotify.get_player_status(access_token)

    # new song is
    state =
      if state.next_queued_song != nil && status.item.id == state.next_queued_song.track_id do
        %{state | current_queued_song: state.next_queued_song, next_queued_song: nil}
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

    {:noreply, state}
  end

  defp queue_next_song(state, access_token) do
    song = Democrify.Session.Worker.fetch_top_track(state.session_pid)

    if state.next_queued_song == nil && song != nil do
      Spotify.add_song_to_queue(song.track_uri, access_token)

      Democrify.Session.delete_song(song, state.session_id)

      %{state | next_queued_song: song}
    else
      state
    end
  end
end
