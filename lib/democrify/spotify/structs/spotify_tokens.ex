defmodule Democrify.Spotify.Tokens do
  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %__MODULE__{
          access_token: String.t(),
          token_type: String.t(),
          scope: String.t(),
          expires_in: Integer.t(),
          refresh_token: String.t()
        }

  defstruct [
    :access_token,
    :token_type,
    :scope,
    :expires_in,
    :refresh_token
  ]

  # ===========================================================
  #  Constructor
  # ===========================================================

  def constructor(response) do
    Poison.decode!(response.body, %{as: %Democrify.Spotify.Tokens{}})
  end
end
