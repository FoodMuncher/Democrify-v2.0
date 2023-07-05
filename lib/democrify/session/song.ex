defmodule Democrify.Session.Song do
  use Ecto.Schema
  import Ecto.Changeset

  @spotify_image_url "https://upload.wikimedia.org/wikipedia/commons/thu…text.svg/1024px-Spotify_logo_without_text.svg.png"

  # TODO: Change this to a struct????
  # TODO: Change user_votes to a MapSet...

  schema "session" do
    field :name,       :string
    field :track_id,   :string
    field :artists,    :string
    field :track_uri,  :string
    field :username,   :string,  default: "Joe"
    field :vote_count, :integer, default: 0
    field :user_votes, :map,     default: Map.new()
    field :image_url,  :string,  default: @spotify_image_url

    timestamps()
  end

  @doc false
  def changeset(song = %__MODULE__{}, attrs) do
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
