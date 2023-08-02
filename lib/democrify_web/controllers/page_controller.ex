defmodule DemocrifyWeb.PageController do
  use DemocrifyWeb, :controller

  require Logger
  alias Democrify.Spotify
  alias Democrify.Session
  alias Democrify.Spotify.Tokens
  alias Democrify.Session.Registry

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
    %Tokens{
      access_token:  access_token,
      refresh_token: refresh_token
    } = Spotify.get_authorisation_tokens(params["code"], type)

    session_id = get_session(conn, "session_id")

    session_id =
      if (type == "create") && (is_nil(session_id) || not Session.exists?(session_id)) do
        Session.create_session(access_token, refresh_token)
      else
        # TODO:  If create, as if the user wants to kill existing session or resume
        session_id
      end

    conn
    |> put_session(:user,          Spotify.get_user_information(access_token))
    |> put_session(:session_id,    session_id)
    |> put_session(:access_token,  access_token)
    |> put_session(:refresh_token, refresh_token)
    |> redirect(to: ~p"/session")
  end

  @doc """
    TODO:
  """
  # TODO: don't meed to fetch access token, can just check if session exists.
  @spec join(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def join(conn, params) do
    case Registry.lookup(params["session_id"]) do
      {:ok, _pid} ->
        conn
        |> put_session(:session_id, params["session_id"])
        |> redirect(to: ~p"/login/join")

      {:error, :notfound} ->
        conn
        |> put_flash(:error, "'#{params["session_id"]}' doesn't look to be a current session!!")
        |> redirect(to: ~p"/")
    end
  end
end
