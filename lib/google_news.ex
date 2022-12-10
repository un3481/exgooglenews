defmodule GoogleNews do
  @moduledoc """

  An Elixir wrapper of the Google News RSS feed.
  Top stories, topic related news feeds, geolocation news feed, and an extensive full text search feed.

  GoogleNews is composed of three main pieces:

    * `GoogleNews` - the high-level API (you're here!)

    * `GoogleNews.Fetch` - the RSS fetching module (includes uri encoding, language options, proxying, etc.)

    * `GoogleNews.Parse` - the parser of the RSS feed (uses FeederEx and Floki packages)

    * `GoogleNews.Search` - the helper functions for building Google News search queries

  The high-level API is what you will use most of the time.

  ## Examples

  Get top news for default 'lang' and 'country' parameters

      iex> {:ok, top} = GoogleNews.top_news(lang: "en", country: "US")
      iex> top.feed.title
      "Top stories - Google News"

  Search for news containing 'boeing' in the title since August, 2022

      iex> {:ok, search} = GoogleNews.search("intitle:boeing", from: "2022-08-01")
      iex> search.feed.title
      "\"intitle:boeing after:2022-08-01\" - Google News"

  """

  alias GoogleNews.Feed
  alias GoogleNews.{Fetch, Parse, Search}
  alias GoogleNews.{FetchError, ParseError}

  @headlines [
    "WORLD",
    "NATION",
    "BUSINESS",
    "TECHNOLOGY",
    "ENTERTAINMENT",
    "SCIENCE",
    "SPORTS",
    "HEALTH"
  ]

  @doc """
  Returns a list of all articles from the main page of Google News.

  See `GoogleNews.Fetch.fetch!/2` for a list of supported options.

  ## Examples

  With default options:

      iex> top = GoogleNews.top_news!()
      iex> top.feed.title
      "Top stories - Google News"

  With custom lang options:

      iex> top = GoogleNews.top_news!(lang: "uk", country: "UA")
      iex> top.feed.title
      "Головні новини - Google Новини"

  """
  @spec top_news!(options :: keyword()) :: Feed.t()
  def top_news!(opts \\ []) when is_list(opts) do
    ""
    |> Fetch.fetch!(opts)
    |> Parse.parse!()
  end

  @doc """
  Returns a list of all articles from the main page of Google News.

  See `GoogleNews.Fetch.fetch!/2` for a list of supported options.

  ## Examples

  With default options:

      iex> {:ok, top} = GoogleNews.top_news!()
      iex> top.feed.title
      "Top stories - Google News"

  With custom lang options:

      iex> {:ok, top} = GoogleNews.top_news(lang: "uk", country: "UA")
      iex> top.feed.title
      "Головні новини - Google Новини"

  """
  @spec top_news(options :: keyword()) :: {:ok, Feed.t()} | {:error, Exception.t()}
  def top_news(opts \\ []) do
    {:ok, top_news!(opts)}
  rescue
    error in [FetchError, ParseError, ArgumentError, FunctionClauseError] ->
      {:error, error}
  end

  @doc """
  Returns a list of all articles from the `topic` page of Google News.

  See `GoogleNews.Fetch.fetch!/2` for a list of supported options.

  ## Examples

  With default options:

      iex> sports = GoogleNews.topic_headlines!("Sports")
      iex> sports.feed.title
      "Sports - Latest - Google News"

  With custom lang options:

      iex> sports = GoogleNews.topic_headlines!("Sports", lang: "uk", country: "UA")
      iex> sports.feed.title
      "Спорт - Останні - Google Новини"

  """
  @spec topic_headlines!(binary, options :: keyword()) :: Feed.t()
  def topic_headlines!(topic, opts \\ []) when is_binary(topic) and is_list(opts) do
    u_topic = String.upcase(topic)

    url =
      if u_topic in @headlines,
        do: "/headlines/section/topic/#{u_topic}",
        else: "/topics/#{topic}"

    url
    |> Fetch.fetch!(opts)
    |> Parse.parse!()
  end

  @doc """
  Returns a list of all articles from the `topic` page of Google News.

  See `GoogleNews.Fetch.fetch!/2` for a list of supported options.

  ## Examples

  With default options:

      iex> {:ok, sports} = GoogleNews.topic_headlines("Sports")
      iex> sports.feed.title
      "Sports - Latest - Google News"

  With custom lang options:

      iex> {:ok, sports} = GoogleNews.topic_headlines("Sports", lang: "uk", country: "UA")
      iex> sports.feed.title
      "Спорт - Останні - Google Новини"

  """
  @spec topic_headlines(binary, options :: keyword()) :: {:ok, Feed.t()} | {:error, Exception.t()}
  def topic_headlines(geo, opts \\ []) do
    {:ok, topic_headlines!(geo, opts)}
  rescue
    error in [FetchError, ParseError, ArgumentError, FunctionClauseError] ->
      {:error, error}
  end

  @doc """
  Returns a list of all articles about a specific geolocation.

  See `GoogleNews.Fetch.fetch!/2` for a list of supported options.

  ## Examples

  With default options:

      iex> poland = GoogleNews.geo_headlines!("Poland")
      iex> poland.feed.title
      "Poland - Latest - Google News"

  With custom lang options:

      iex> poland = GoogleNews.geo_headlines!("Poland", lang: "uk", country: "UA")
      iex> poland.feed.title
      "Польща - Останні - Google Новини"

  """
  @spec geo_headlines!(binary, options :: keyword()) :: Feed.t()
  def geo_headlines!(geo, opts \\ []) when is_binary(geo) and is_list(opts) do
    "/headlines/section/geo/#{geo}"
    |> Fetch.fetch!(opts)
    |> Parse.parse!()
  end

  @doc """
  Returns a list of all articles about a specific geolocation.

  See `GoogleNews.Fetch.fetch!/2` for a list of supported options.

  ## Examples

  With default options:

      iex> {:ok, poland} = GoogleNews.geo_headlines("Poland")
      iex> poland.feed.title
      "Poland - Latest - Google News"

  With custom lang options:

      iex> {:ok, poland} = GoogleNews.geo_headlines("Poland", lang: "uk", country: "UA")
      iex> poland.feed.title
      "Польща - Останні - Google Новини"

  """
  @spec geo_headlines(binary, options :: keyword()) :: {:ok, Feed.t()} | {:error, Exception.t()}
  def geo_headlines(geo, opts \\ []) do
    {:ok, geo_headlines!(geo, opts)}
  rescue
    error in [FetchError, ParseError, ArgumentError, FunctionClauseError] ->
      {:error, error}
  end

  @doc """
  Returns a list of all articles given a full-text search parameter.

  See `GoogleNews.Fetch.fetch!/2` and `GoogleNews.Search.query!/2` for a list of supported options.

  ## Examples

  With default options:

      iex> search = GoogleNews.search!("boeing", from: "2022-08-01")
      iex> search.feed.title
      "\"boeing after:2022-08-01\" - Google News"

  With custom lang options:

      iex> search = GoogleNews.search!("boeing", from: "2022-08-01", lang: "uk", country: "UA")
      iex> search.feed.title
      "\"boeing after:2022-08-01\" - Google Новини"

  """
  @spec search!(binary, options :: keyword()) :: Feed.t()
  def search!(query, opts \\ []) when is_binary(query) and is_list(opts) do
    query = Search.query!(query, opts)

    "/search?q=#{query}"
    |> Fetch.fetch!(opts)
    |> Parse.parse!()
  end

  @doc """
  Returns a list of all articles given a full-text search parameter.

  See `GoogleNews.Fetch.fetch!/2` and `GoogleNews.Search.query!/2` for a list of supported options.

  ## Examples

  With default options:

      iex> {:ok, search} = GoogleNews.search("boeing", from: "2022-08-01")
      iex> search.feed.title
      "\"boeing after:2022-08-01\" - Google News"

  With custom lang options:

      iex> {:ok, search} = GoogleNews.search("boeing", from: "2022-08-01", lang: "uk", country: "UA")
      iex> search.feed.title
      "\"boeing after:2022-08-01\" - Google Новини"

  """
  @spec search(binary, options :: keyword()) :: {:ok, Feed.t()} | {:error, Exception.t()}
  def search(query, opts \\ []) do
    {:ok, search!(query, opts)}
  rescue
    error in [FetchError, ParseError, ArgumentError, FunctionClauseError] ->
      {:error, error}
  end
end
