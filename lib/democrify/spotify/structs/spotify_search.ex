defmodule Democrify.Spotify.Search do
  alias Democrify.Spotify.Tracks

  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %__MODULE__{
          tracks: Tracks.t()
        }

  defstruct [
    :tracks
  ]

  # ===========================================================
  #  Constructor
  # ===========================================================

  def constructor(response) do
    Poison.decode!(response.body, %{
      as: %__MODULE__{
        :tracks => Tracks.structure()
      }
    })
  end
end
