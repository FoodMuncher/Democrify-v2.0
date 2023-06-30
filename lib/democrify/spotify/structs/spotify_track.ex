defmodule Democrify.Spotify.Track do
  alias Democrify.Spotify.{Artist, Album}

  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %Democrify.Spotify.Track{
          album: Album.t(),
          artists: [%Artist{}],
          name: String.t(),
          id: String.t(),
          duration_ms: Integer.t()
        }

  defstruct [
    :album,
    :artists,
    :name,
    :id,
    :duration_ms,
    :uri
  ]

  # ===========================================================
  #  Constructor
  # ===========================================================

  def constructor(response) do
    Poison.decode!(response.body, %{
      as: structure()
    })
  end

  # ===========================================================
  #  Nested Struct Structure
  # ===========================================================

  def structure do
    %__MODULE__{
      artists: [%Artist{}],
      album: Album.structure()
    }
  end
end
