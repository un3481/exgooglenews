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

  # Handle FeederEx response
  defp handle_feed({:ok, value, _}) when is_map(value), do: value

  defp handle_feed({:fatal_error, _, reason, _, _}) do
    raise(ParseError, reason: :parser_error, value: reason)
  end

  defp handle_feed({:error, error}) do
    raise(ParseError, reason: :parser_error, value: error)
  end

  defp handle_feed(value) do
    raise(ParseError, reason: :invalid_output, value: value)
  end

  # Parse subarticles from feed.
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

  # Get subarticles from entry
  defp sub_articles(entry) do
    summary = Map.get(entry, :summary)

    if is_binary(summary),
      do: sub_articles_parse(summary),
      else: []
  end

  # Separate FeederEx Feed from Entries
  defp format(value) do
    feed =
      value
      |> Map.delete(:entries)
      |> Map.put(:__struct__, FeedInfo)

    entries =
      value
      |> Map.get(:entries)
      |> Enum.map(fn item ->
        item
        |> Map.put(:sub_articles, sub_articles(item))
        |> Map.put(:__struct__, Entry)
      end)

    %Feed{feed: feed, entries: entries}
  end

  @doc """
  Parse RSS Feed
  """
  @spec parse!(String.t()) :: Feed.t()
  def parse!(rss) when is_binary(rss) do
    rss
    |> FeederEx.parse()
    |> handle_feed()
    |> format()
  end
end
