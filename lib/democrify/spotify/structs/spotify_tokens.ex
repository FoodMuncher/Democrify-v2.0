defmodule Democrify.Spotify.Tokens do
  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %__MODULE__{
    scope:         String.t(),
    token_type:    String.t(),
    expires_in:    Integer.t(),
    access_token:  String.t(),
    refresh_token: String.t()
  }

  defstruct [
    :scope,
    :token_type,
    :expires_in,
    :access_token,
    :refresh_token
  ]

  # ===========================================================
  #  Constructor
  # ===========================================================

  def constructor(response) do
    Poison.decode!(response.body, %{as: %__MODULE__{}})
  end
end
