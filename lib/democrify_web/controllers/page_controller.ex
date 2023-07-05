defmodule DemocrifyWeb.PageController do
  use DemocrifyWeb, :controller

  require Logger
  alias Democrify.Spotify
  alias Democrify.Session
  alias Democrify.Session.Data, as: SessionData

  # ===========================================================
  # Home Page Handlers
  # ===========================================================

  @doc """
    Handles the static loading of the home page
  """
  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    conn
    |> put_layout(false)
    |> render("index.html")
  end

  # ===========================================================
  #  Spotify Login Handlers
  # ===========================================================

  @doc """
    TODO:
  """
  @spec login(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def login(conn, %{"type" => type} = params) when type in ["create", "join"] do
    Logger.info("Params: #{inspect params}")
    redirect(conn, external: Spotify.authorize_url(type))
  end

  @doc """
    TODO:
  """
  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def callback(conn, %{"type" => type} = params) when type in ["create", "join"] do
    authorisation_tokens = Spotify.get_authorisation_tokens(params["code"], type)

    session_id = get_session(conn, "session_id")

    session_id =
      if (type == "create") && (is_nil(session_id) || not Session.exists?(session_id)) do
        Session.create_session()
      else
        # TODO:  If create, as if the user wants to kill existing session or resume
        session_id
      end

    access_token = authorisation_tokens.access_token

    SessionData.add(session_id, access_token)

    conn
    |> put_session(:user,         Spotify.get_user_information(access_token))
    |> put_session(:session_id,   session_id)
    |> put_session(:access_token, access_token)
    |> redirect(to: ~p"/session")
  end

  @doc """
    TODO:
  """
  @spec join(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def join(conn, params) do
    case SessionData.fetch(params["session_id"]) do
      [{session_id, access_token}] ->
        conn
        |> put_session(:session_id,   session_id)
        |> put_session(:access_token, access_token)
        |> redirect(to: ~p"/login/join")

      [] ->
        conn
        |> put_flash(:error, "'#{params["session_id"]}' doesn't look to be a current session!!")
        |> redirect(to: ~p"/")
    end
  end
end
