defmodule Democrify.Session.Song do
  use Ecto.Schema
  import Ecto.Changeset

  @spotify_image_url "https://upload.wikimedia.org/wikipedia/commons/thu…text.svg/1024px-Spotify_logo_without_text.svg.png"

  schema "session" do
    field(:name, :string)
    field(:username, :string, default: "Joe")
    field(:votes, :integer, default: 0)
    field(:track_id, :string)
    field(:artists, :string)
    field(:image_url, :string, default: @spotify_image_url)
    field(:track_uri, :string)

    timestamps()
  end

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def artists([artist]) do
    "#{artist.name}"
  end

  def artists([artist | artists]) do
    "#{artist.name}, #{artists(artists)}"
  end
end
