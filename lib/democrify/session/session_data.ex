defmodule Democrify.Session.Data do
  @moduledoc """
  ETS table used to store session data which is loaded into
  the clients hhtp_session when they join a session
  """

  # ===========================================================
  # API functions
  # ===========================================================

  def start(_opts \\ []) do
    :ets.new(__MODULE__, [:named_table, :public, {:read_concurrency, true}])
  end

  def add(session_id, access_token) do
    :ets.insert(__MODULE__, {session_id, access_token})
  end

  @spec fetch(any) :: [tuple]
  def fetch(session_id) do
    :ets.lookup(__MODULE__, session_id)
  end

  def fetch!(session_id) do
    [{^session_id, access_token}] = fetch(session_id)
    access_token
  end

  def list_all do
    :ets.tab2list(__MODULE__)
  end
end
