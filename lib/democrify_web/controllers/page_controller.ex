defmodule DemocrifyWeb.PageController do
  use DemocrifyWeb, :controller

  require Logger
  alias Democrify.Spotify
  alias Democrify.Session
  alias Democrify.Spotify.{Tokens, Profile}
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
      expires_in: expires_in,
      access_token: access_token,
      refresh_token: refresh_token
    } = Spotify.get_authorisation_tokens(params["code"], type)

    session_id = get_session(conn, "session_id")

    user = %Profile{id: user_id} = Spotify.get_user_information(access_token)

    spotify_data = %Spotify{
      user_id:       user_id,
      expiry_time:   DateTime.add(DateTime.utc_now(), expires_in),
      access_token:  access_token,
      refresh_token: refresh_token
    }

    session_id =
      if type == "create" && not Session.exists?(session_id) do
        Session.create_session(spotify_data)
      else
        # TODO:  If create, ask if the user wants to kill existing session or resume
        session_id
      end

    conn
    |> put_session(:user,          user)
    |> put_session(:session_id,    session_id)
    |> put_session(:spotify_data,  spotify_data)
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
