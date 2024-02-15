defmodule Democrify.Session.Song do
  @spotify_image_url "https://upload.wikimedia.org/wikipedia/commons/thu…text.svg/1024px-Spotify_logo_without_text.svg.png"

  alias Democrify.Spotify.Artist

  # TODO: Create song in here

  # ========================================
  # Exported Functions
  # ========================================

  defstruct [
    :id,
    :name,
    :artists,
    :user_id,
    :username,
    :track_id,
    :track_uri,
    image_url:  @spotify_image_url,
    vote_count: 0,
    user_votes: MapSet.new()
  ]

  @type t() :: %__MODULE__{
    id:         String.t(),
    name:       String.t(),
    artists:    String.t(),
    user_id:    String.t(),
    username:   String.t(),
    track_id:   String.t(),
    track_uri:  String.t(),
    vote_count: integer(),
    user_votes: MapSet.t(String.t()),
    image_url:  String.t()
  }

  # ========================================
  # Exported Functions
  # ========================================

  @doc """
    Creates a string of all the artist names, from a list of Artists structs
  """
  @spec artists([Artist.t()]) :: String.t()
  def artists([artist]) do
    "#{artist.name}"
  end
  def artists([artist | artists]) do
    "#{artist.name}, #{artists(artists)}"
  end
end
