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

  @doc """
  Return a list of all articles from the main page of Google News given a country and a language.
  """
  @spec top_news!(list) :: Feed.t()
  def top_news!(opts \\ []) when is_list(opts) do
    data =
      ""
      |> Fetch.fetch!(opts)
      |> Parse.parse!()

    %{data | entries: SubArticles.merge!(data.entries)}
  end

  @doc """
  Return a list of all articles from the main page of Google News given a country and a language.
  """
  @spec top_news(list) :: {:ok, Feed.t()} | {:error, term}
  def top_news(opts \\ []) do
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
    u_topic = String.upcase(topic)

    url =
      if u_topic in @headlines,
        do: "/headlines/section/topic/#{u_topic}",
        else: "/topics/#{topic}"

    data =
      url
      |> Fetch.fetch!(opts)
      |> Parse.parse!()

    %{data | entries: SubArticles.merge!(data.entries)}
  end

  @doc """
  Return a list of all articles from the topic page of Google News given a country and a language.
  """
  @spec topic_headlines(binary, list) :: {:ok, Feed.t()} | {:error, term}
  def topic_headlines(geo, opts \\ []) do
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
    data =
      "/headlines/section/geo/#{geo}"
      |> Fetch.fetch!(opts)
      |> Parse.parse!()

    %{data | entries: SubArticles.merge!(data.entries)}
  end

  @doc """
  Return a list of all articles about a specific geolocation given a country and a language.
  """
  @spec geo_headlines(binary, list) :: {:ok, Feed.t()} | {:error, term}
  def geo_headlines(geo, opts \\ []) do
    {:ok, geo_headlines!(geo, opts)}
  rescue
    error in [Error, FetchError, ParseError, ArgumentError] ->
      {:error, error}
  end

  @doc """
  Return a list of all articles given a full-text search parameter, a country and a language.

  @param boolean encode: When True helps with URL quoting.
  @param binary when: Sets a time range for the artiles that can be found.
  """
  @spec search!(binary, list) :: Feed.t()
  def search!(query, opts \\ []) when is_binary(query) and is_list(opts) do
    query = Search.query!(query, opts)

    data =
      "/search?q=#{query}"
      |> Fetch.fetch!(opts)
      |> Parse.parse!()

    %{data | entries: SubArticles.merge!(data.entries)}
  end

  @doc """
  Return a list of all articles given a full-text search parameter, a country and a language.

  @param boolean encode: When True helps with URL quoting.
  @param binary when: Sets a time range for the artiles that can be found.
  """
  @spec search(binary, list) :: {:ok, Feed.t()} | {:error, term}
  def search(query, opts \\ []) do
    {:ok, search!(query, opts)}
  rescue
    error in [Error, FetchError, ParseError, ArgumentError] ->
      {:error, error}
  end
end
