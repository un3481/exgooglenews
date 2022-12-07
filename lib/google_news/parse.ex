defmodule GoogleNews.FeedInfo do
  defstruct author: nil,
            id: nil,
            image: nil,
            link: nil,
            language: nil,
            subtitle: nil,
            summary: nil,
            title: nil,
            updated: nil,
            url: nil
end

defmodule GoogleNews.Entry do
  defstruct author: nil,
            categories: [],
            duration: nil,
            enclosure: nil,
            id: nil,
            image: nil,
            link: nil,
            subtitle: nil,
            summary: nil,
            title: nil,
            updated: nil,
            sub_articles: []
end

defmodule GoogleNews.Feed do
  defstruct feed: %GoogleNews.FeedInfo{}, entries: []

  @typedoc """
  Struct that contains Parsed RSS Feed information.
  """
  @type t :: %__MODULE__{
          feed: GoogleNews.FeedInfo.t(),
          entries: [GoogleNews.Entry.t()]
        }
end

defmodule GoogleNews.ParseError do
  @type t :: %__MODULE__{message: String.t(), value: any}

  defexception message: nil, value: nil

  def message(%{message: nil, value: value}) do
    "Could not parse the feed: #{inspect(value)}"
  end

  def message(%{message: message}) do
    message
  end
end

defmodule GoogleNews.Parse do
  alias GoogleNews.{Feed, FeedInfo, Entry}
  alias GoogleNews.{SubArticles}
  alias GoogleNews.{Error, ParseError}

  # Separate FeederEx Feed from Entries
  defp format_map({:ok, map, _}) when is_map(map) do
    feed =
      map
      |> Map.delete(:entries)
      |> Map.merge(%{__struct__: FeedInfo})

    entries =
      map
      |> Map.get(:entries)
      |> Enum.map(fn item ->
        item
        |> Map.merge(%{__struct__: Entry})
        |> SubArticles.merge!()
      end)

    %Feed{feed: feed, entries: entries}
  end

  defp format_map({:fatal_error, _, reason, _, _}), do: raise(ParseError, message: reason)
  defp format_map({:error, reason}), do: raise(ParseError, message: reason)
  defp format_map(unknown), do: raise(Error, message: "Invalid return", value: unknown)

  @doc """
  Parse RSS Feed
  """
  @spec parse!(String.t()) :: Feed.t()
  def parse!(rss) when is_binary(rss) do
    rss
    |> FeederEx.parse()
    |> format_map()
  end
end
