defmodule GoogleNews.SubArticle do
  defstruct title: nil, url: nil, publisher: nil

  @typedoc """
  Struct that contains Sub-articles information.
  """
  @type t :: %__MODULE__{
          title: binary,
          url: binary,
          publisher: binary
        }
end

defmodule GoogleNews.SubArticles do
  alias GoogleNews.SubArticle

  # Return subarticles from the main and topic feeds.
  defp parser(text) do
    text
    |> Floki.parse_document!()
    |> Floki.find("li")
    |> Enum.map(fn li ->
      a = Floki.find(li, "a")
      font = Floki.find(li, "font")

      %SubArticle{
        title: Floki.text(a),
        url: Floki.attribute(a, "href") |> Enum.at(0),
        publisher: Floki.text(font)
      }
    end)
  end

  @doc """
  Merge Sub Articles to entries
  """
  @spec merge!(map) :: map
  def merge!(entry) when is_map(entry) do
    summary = Map.get(entry, :summary)
    sub_articles = if is_binary(summary), do: parser(summary), else: []
    Map.put(entry, :sub_articles, sub_articles)
  end
end
