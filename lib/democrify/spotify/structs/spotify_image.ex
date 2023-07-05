defmodule Democrify.Spotify.Image do
  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %Democrify.Spotify.Image{
    url:    String.t(),
    width:  Integer.t(),
    height: Integer.t()
  }

  defstruct [
    :url,
    :width,
    :height
  ]
end
