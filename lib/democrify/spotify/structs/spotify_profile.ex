defmodule Democrify.Spotify.Profile do
  alias Democrify.Spotify.Image

  # ===========================================================
  #  Struct
  # ===========================================================

  @type t() :: %__MODULE__{
    id:           String.t(),
    images:       Integer.t(),
    display_name: String.t()
  }

  defstruct [
    :id,
    :images,
    :display_name
  ]

  # ===========================================================
  #  Constructor
  # ===========================================================

  @doc """
    Decodes the HTTP repsonse into a struct.
  """
  @spec constructor(map()) :: t()
  def constructor(response) do
    Poison.decode!(response.body, %{as: structure()})
  end

  # ===========================================================
  #  Nested Struct Structure
  # ===========================================================

  @doc """
    Returns the structure that the HTTP response should be decoded to.
  """
  @spec structure() :: %__MODULE__{}
  def structure() do
    %__MODULE__{
      images: [%Image{}]
    }
  end
end
