defmodule Democrify.Spotify.Track do
  alias Democrify.Spotify.{Artist, Album}

  # ===========================================================
  #  Struct
  # ===========================================================

  @type t :: %Democrify.Spotify.Track{
    id:          String.t(),
    name:        String.t(),
    album:       Album.t(),
    artists:     [%Artist{}],
    duration_ms: Integer.t()
  }

  defstruct [
    :id,
    :uri,
    :name,
    :album,
    :artists,
    :duration_ms
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
