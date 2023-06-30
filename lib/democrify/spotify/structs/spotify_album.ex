defmodule Democrify.Spotify.Album do
  alias Democrify.Spotify.Image

  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %__MODULE__{
          images: [Image.t()]
        }

  defstruct [
    :images
  ]

  # ===========================================================
  #  Nested Struct Structure
  # ===========================================================

  def structure do
    %__MODULE__{
      :images => [%Image{}]
    }
  end
end
