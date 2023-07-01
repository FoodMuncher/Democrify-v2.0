defmodule DemocrifyWeb.PageController do
  use DemocrifyWeb, :controller

  alias Democrify.Spotify
  alias Democrify.Session
  alias Democrify.Session.Data, as: SessionData

  # ===========================================================
  # Home Page Handlers
  # ===========================================================

  def index(conn, _params) do
    conn
    |> put_layout(false)
    |> render("index.html")
  end

  def join(conn, params) do
    # TODO: Check session exists, if it doesn't send to home with a flash card

    session_id = params["session_id"]

    access_token = SessionData.fetch!(session_id)

    conn
    |> put_session(:session_id, session_id)
    |> put_session(:access_token, access_token)
    |> redirect(to: ~p"/session")
  end

  # ===========================================================
  #  Spotify Login Handlers
  # ===========================================================

  def login(conn, _params) do
    redirect(conn, external: Spotify.authorize_url())
  end

  def callback(conn, params) do
    authorisation_tokens = Spotify.get_authorisation_tokens(params["code"])

    session_id = get_session(conn, "session_id")
    # TODO: kill existing session, or ask to resume
    session_id =
      if session_id == nil || not Session.exists?(session_id) do
        Session.create_session()
      else
        session_id
      end

    access_token = authorisation_tokens.access_token

    SessionData.add(session_id, access_token)

    conn
    |> put_session(:session_id, session_id)
    |> put_session(:access_token, access_token)
    |> redirect(to: ~p"/session")
  end
end
