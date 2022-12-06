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

defmodule GoogleNews.Feed do
  defstruct feed: nil, entries: []

  @typedoc """
  Struct that contains Parsed RSS Feed information.
  """
  @type t :: %__MODULE__{
          feed: FeederEx.Feed.t(),
          entries: [FeederEx.Entry.t()]
        }
end

defmodule GoogleNews.Parse do
  alias GoogleNews.{Feed, Error, ParseError}

  # Separate FeederEx Feed from Entries
  defp format_map({:ok, map, _}) when is_map(map) do
    %Feed{
      feed: Map.delete(map, :entries),
      entries: Map.get(map, :entries)
    }
  end

  defp format_map({:fatal_error, _, reason, _, _}), do: raise(ParseError, message: reason)
  defp format_map({:error, reason}), do: raise(ParseError, message: reason)
  defp format_map(unknown), do: raise(Error, message: "Invalid return", value: unknown)

  @doc """
  Parse RSS Feed
  """
  @spec feed!(String.t()) :: Feed.t()
  def feed!(rss) when is_binary(rss) do
    rss
    |> FeederEx.parse()
    |> format_map()
  end
end