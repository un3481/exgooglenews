defmodule GoogleNews do
  @moduledoc """
  Documentation for `GoogleNews`.
  """

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

  alias GoogleNews.Feed
  alias GoogleNews.{Error, FetchError, ParseError}
  alias GoogleNews.{Fetch, Parse, SubArticles, Search}

  # Compile correct country-lang parameters for Google News RSS URL.
  defp ceid(opts) when is_list(opts) do
    lang = Keyword.get(opts, :lang, "en")
    country = Keyword.get(opts, :country, "US")
    "ceid=#{country}:#{lang}&hl=#{lang}&gl=#{country}"
  end

  @doc """
  Return a list of all articles from the main page of Google News given a country and a language.
  """
  @spec top_news!(list) :: Feed.t()
  def top_news!(opts \\ []) when is_list(opts) do
    proxy = Keyword.get(opts, :proxy)
    scraping_bee = Keyword.get(opts, :scraping_bee)

    data =
      ("?" <> ceid(opts))
      |> Fetch.feed!(proxy, scraping_bee)
      |> Parse.feed!()

    %{data | entries: SubArticles.merge!(data.entries)}
  end

  @doc """
  Return a list of all articles from the main page of Google News given a country and a language.
  """
  @spec top_news(list) :: {:ok, Feed.t()} | {:error, term}
  def top_news(opts \\ []) when is_list(opts) do
    {:ok, top_news!(opts)}
  rescue
    error in [Error, FetchError, ParseError, ArgumentError] ->
      {:error, error}
  end

  @doc """
  Return a list of all articles from the topic page of Google News given a country and a language.
  """
  @spec topic_headlines!(binary, list) :: Feed.t()
  def topic_headlines!(topic, opts \\ []) when is_binary(topic) and is_list(opts) do
    proxy = Keyword.get(opts, :proxy)
    scraping_bee = Keyword.get(opts, :scraping_bee)

    u_topic = String.upcase(topic)

    url =
      if u_topic in @headlines,
        do: "/headlines/section/topic/#{u_topic}?",
        else: "/topics/#{topic}?"

    data =
      (url <> ceid(opts))
      |> Fetch.feed!(proxy, scraping_bee)
      |> Parse.feed!()

    entries = SubArticles.merge!(data.entries)
    if Enum.empty?(entries), do: raise(Error, message: "Unsupported topic")

    %{data | entries: entries}
  end

  @doc """
  Return a list of all articles from the topic page of Google News given a country and a language.
  """
  @spec topic_headlines(binary, list) :: {:ok, Feed.t()} | {:error, term}
  def topic_headlines(geo, opts \\ []) when is_binary(geo) and is_list(opts) do
    {:ok, topic_headlines!(geo, opts)}
  rescue
    error in [Error, FetchError, ParseError, ArgumentError] ->
      {:error, error}
  end

  @doc """
  Return a list of all articles about a specific geolocation given a country and a language.
  """
  @spec geo_headlines!(binary, list) :: Feed.t()
  def geo_headlines!(geo, opts \\ []) when is_binary(geo) and is_list(opts) do
    proxy = Keyword.get(opts, :proxy)
    scraping_bee = Keyword.get(opts, :scraping_bee)

    data =
      ("/headlines/section/geo/#{geo}?" <> ceid(opts))
      |> Fetch.feed!(proxy, scraping_bee)
      |> Parse.feed!()

    %{data | entries: SubArticles.merge!(data.entries)}
  end

  @doc """
  Return a list of all articles about a specific geolocation given a country and a language.
  """
  @spec geo_headlines(binary, list) :: {:ok, Feed.t()} | {:error, term}
  def geo_headlines(geo, opts \\ []) when is_binary(geo) and is_list(opts) do
    {:ok, geo_headlines!(geo, opts)}
  rescue
    error in [Error, FetchError, ParseError, ArgumentError] ->
      {:error, error}
  end

  @doc """
  Return a list of all articles given a full-text search parameter, a country and a language.

  @param boolean helper: When True helps with URL quoting.
  @param binary when: Sets a time range for the artiles that can be found.
  """
  @spec search!(binary, list) :: Feed.t()
  def search!(query, opts \\ []) when is_binary(query) and is_list(opts) do
    proxy = Keyword.get(opts, :proxy)
    scraping_bee = Keyword.get(opts, :scraping_bee)

    query =
      Search.query!(
        query,
        Keyword.get(opts, :helper, true),
        Keyword.get(opts, :when),
        Keyword.get(opts, :from),
        Keyword.get(opts, :to)
      )

    data =
      ("/search?q=#{query}&" <> ceid(opts))
      |> Fetch.feed!(proxy, scraping_bee)
      |> Parse.feed!()

    %{data | entries: SubArticles.merge!(data.entries)}
  end

  @doc """
  Return a list of all articles given a full-text search parameter, a country and a language.

  @param boolean helper: When True helps with URL quoting.
  @param binary when: Sets a time range for the artiles that can be found.
  """
  @spec search(binary, list) :: {:ok, Feed.t()} | {:error, term}
  def search(query, opts \\ []) when is_binary(query) and is_list(opts) do
    {:ok, search!(query, opts)}
  rescue
    error in [Error, FetchError, ParseError, ArgumentError] ->
      {:error, error}
  end
end
