defmodule GoogleNews.ParseError do
  @type t :: %__MODULE__{reason: atom, value: any}

  defexception reason: nil, value: nil

  def message(%{reason: reason, value: value}) do
    case reason do
      :parser_error -> "error on rss parser: #{inspect(value)}"
      :invalid_output -> "invalid output from rss parser: #{inspect(value)}"
      _ -> "could not parse the feed: #{inspect(value)}"
    end
  end
end

defmodule GoogleNews.Parse do
  alias GoogleNews.{Feed, FeedInfo, Entry, SubArticle}
  alias GoogleNews.ParseError

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
  rescue
    _ -> []
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
  defp handle_feed({:ok, value, _}) when is_map(value) do
    feed =
      value
      |> Map.delete(:entries)
      |> Map.put(:__struct__, FeedInfo)

    entries =
      value
      |> Map.get(:entries)
      |> Enum.map(fn item ->
        item
        |> sub_articles_merge()
        |> Map.put(:__struct__, Entry)
      end)

    %Feed{feed: feed, entries: entries}
  end

  defp handle_feed({:fatal_error, _, reason, _, _}) do
    raise(ParseError, reason: :parser_error, value: reason)
  end

  defp handle_feed({:error, error}) do
    raise(ParseError, reason: :parser_error, value: error)
  end

  defp handle_feed(value) do
    raise(ParseError, reason: :invalid_output, value: value)
  end

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
