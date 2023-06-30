defmodule Democrify.Spotify.Image do
  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %Democrify.Spotify.Image{
          url: String.t(),
          height: Integer.t(),
          width: Integer.t()
        }

  defstruct [
    :url,
    :height,
    :width
  ]
end
