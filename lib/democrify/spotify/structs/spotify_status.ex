defmodule Democrify.Spotify.Status do
  alias Democrify.Spotify.Track

  defstruct [
    :timestamp,
    :progress_ms,
    :is_playing,
    :item
  ]

  def constructor(response) when response.status_code == 200 do
    Poison.decode!(response.body, %{as: structure()})
  end

  def constructor(response) when response.status_code == 204 do
    nil
  end

  def structure do
    %__MODULE__{
      item: Track.structure()
    }
  end
end
