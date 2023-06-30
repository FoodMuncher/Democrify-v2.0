defmodule Democrify.Spotify.Artist do
  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %__MODULE__{
          name: String.t()
        }

  defstruct [
    :name
  ]
end
