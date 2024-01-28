defmodule Democrify.Spotify.Tracks do
  alias Democrify.Spotify.Track

  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %__MODULE__{
    items: [Track.t()]
  }

  defstruct [
    :items
  ]

  # ===========================================================
  #  Nested Struct Structure
  # ===========================================================

  def structure do
    %__MODULE__{
      :items => [Track.structure()]
    }
  end
end
