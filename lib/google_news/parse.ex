defmodule GoogleNews.ParseError do
  @type t :: %__MODULE__{message: String.t(), value: any}

  defexception message: nil, value: nil

  def message(%{message: nil, value: value}) do
    "could not parse the feed: #{inspect(value)}"
  end

  def message(%{message: message}) do
    message
  end
end

defmodule GoogleNews.Parse do
  alias GoogleNews.{Feed, FeedInfo, Entry, SubArticle}
  alias GoogleNews.{Error, ParseError}

  # Return subarticles from the main and topic feeds.
  defp sub_articles_parse(text) do
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

  # Merge subarticles to entry
  defp sub_articles_merge(entry) do
    summary = Map.get(entry, :summary)

    sub_articles =
      if is_binary(summary),
        do: sub_articles_parse(summary),
        else: []

    Map.put(entry, :sub_articles, sub_articles)
  end

  # Separate FeederEx Feed from Entries
  defp handle_feed({:ok, map, _}) when is_map(map) do
    feed =
      map
      |> Map.delete(:entries)
      |> Map.put(:__struct__, FeedInfo)

    entries =
      map
      |> Map.get(:entries)
      |> Enum.map(fn item ->
        item
        |> sub_articles_merge()
        |> Map.put(:__struct__, Entry)
      end)

    %Feed{feed: feed, entries: entries}
  end

  defp handle_feed({:fatal_error, _, reason, _, _}), do: raise(ParseError, value: reason)
  defp handle_feed({:error, error}), do: raise(ParseError, value: error)
  defp handle_feed(unknown), do: raise(Error, message: "invalid return", value: unknown)

  @doc """
  Parse RSS Feed
  """
  @spec parse!(String.t()) :: Feed.t()
  def parse!(rss) when is_binary(rss) do
    rss
    |> FeederEx.parse()
    |> handle_feed()
  end
end
