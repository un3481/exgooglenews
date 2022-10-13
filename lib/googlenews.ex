defmodule Googlenews do
  @moduledoc """
  Documentation for `Googlenews`.
  """

  @base_url "https://news.google.com/rss"
  # @unsupported "https://news.google.com/rss/unsupported"

  @default_options [lang: "en", country: "US"]

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

  @typedoc """
  Proxy configuration for Mint package.
  """
  @type proxy_descriptor :: {atom, String.t, integer, list}

  @typedoc """
  Result of parsing a RSS Feed.
  """
  @type parsed_feed :: %{
    feed: term,
    entries: [FeederEx.Entry.t]
  }

  #
  # Compile correct country-lang parameters for Google News RSS URL.
  #
  defp ceid(opts) when is_list(opts) do
    lang = Keyword.get(opts, :lang)
    country = Keyword.get(opts, :country)
    "ceid=#{country}:#{lang}&hl=#{lang}&gl=#{country}"
  end

  defp search_helper(query) when is_binary(query) do
    URI.encode(query)
  end

  defp from_to_helper(validate) when is_binary(validate) do
    try do
      validate
        |> Date.from_iso8601!
        |> Date.to_iso8601
    catch _, _ -> throw "Could not parse your date"
    end
  end

  #
  # Process search query options
  #
  def process_query(query, helper, when_, _, _) when is_binary(when_), do:
    process_query(query <> " when:" <> when_, helper, nil, nil, nil)

  def process_query(query, helper, _, from, to) when is_binary(from), do:
    process_query(query <> " after:" <> from_to_helper(from), helper, nil, nil, to)

  def process_query(query, helper, _, _, to) when is_binary(to), do:
    process_query(query <> " before:" <> from_to_helper(to), helper, nil, nil, nil)

  def process_query(query, helper, _, _, _) when helper, do: search_helper(query)
  def process_query(query, _, _, _, _), do: query

  #
  # Return subarticles from the main and topic feeds.
  #
  defp top_news_parser(text) when is_binary(text) do
    text
      |> Floki.parse_document!
      |> Floki.find("li")
      |> Enum.map(
        fn li ->
          a = Floki.find li, "a"
          font = Floki.find li, "font"
          %{
            title: Floki.text(a),
            url: Floki.attribute(a, "href"),
            publisher: Floki.text(font)
          }
        end
      )
  end

  defp add_sub_articles(entries) when is_list(entries) do
    entries
      |> Enum.map(
        fn entry -> Map.merge(
          entry,
          %{
            sub_articles:
              if Map.get(entry, :summary) != nil do
                top_news_parser Map.get(entry, :summary)
              else nil end
          }
        ) end
      )
  end

  #
  # Retrieve RSS Feed using provided methods.
  #
  defp get_feed(_, proxy, scraping_bee, _) when
    not is_nil(proxy) and
    not is_nil(scraping_bee)
  do
    throw "Pick either ScrapingBee or proxy. Not both!"
  end

  defp get_feed(feed_url, proxy, _, http_client) when
    not is_nil(proxy)
  do
    apply http_client, :get!,
      [
        feed_url,
        [connect_options: [proxy: proxy]]
      ]
  end

  defp get_feed(feed_url, _, scraping_bee, http_client) when
    not is_nil(scraping_bee)
  do
    apply http_client, :post!,
      [
        "https://app.scrapingbee.com/api/v1/",
        [
          json: %{
            url: feed_url,
            api_key: scraping_bee,
            render_js: "false"
          }
        ]
      ]
  end

  defp get_feed(feed_url, _, _, http_client) do
    apply http_client, :get!, [feed_url]
  end

  #
  # Check response for RSS Feed.
  #
  defp check_response(response) when is_map(response) do
    # if @unsupported in response.url do
    #   throw "This feed is not available"
    # end
    unless response.status == 200 do
      throw "status_code: #{response.status} body: \"#{response.body}\""
    end
    response.body
  end

  defp format_map({:ok, map, _}) when is_map(map) do
    %{feed: Map.get(map, :feed), entries: Map.get(map, :entries)}
  end

  #
  # Retrieve and process RSS Feed.
  #
  defp parse_feed(
    feed_url,
    proxy,
    scraping_bee,
    http_client
  ) do
    feed_url
      |> get_feed(proxy, scraping_bee, http_client)
      |> check_response
      |> FeederEx.parse
      |> format_map
  end

  @doc """
  Return a list of all articles from the main page of Google News given a country and a language.
  """
  @spec top_news(list) :: {:ok, parsed_feed} | {:error, term}
  def top_news(opts \\ []) when is_list(opts) do
    try do
      opts = Keyword.merge(@default_options, opts)
      http_client = Keyword.get(opts, :http_client, Req)
      scraping_bee = Keyword.get(opts, :scraping_bee)
      proxy = Keyword.get(opts, :proxy)

      data = parse_feed(
        @base_url <> "?" <> ceid(opts),
        proxy,
        scraping_bee,
        http_client
      )
      data = %{data | entries: add_sub_articles data.entries }

      {:ok, data}
    catch _, reason -> {:error, reason}
    end
  end

  @spec top_news!(list) :: parsed_feed
  def top_news!(opts \\ []) when is_list(opts) do
    top_news(opts) |> Unsafe.Handler.bang!
  end

  @doc """
  Return a list of all articles from the topic page of Google News given a country and a language.
  """
  @spec topic_headlines(String.t, list) :: {:ok, parsed_feed} | {:error, term}
  def topic_headlines(topic, opts \\ []) when is_binary(topic) and is_list(opts) do
    try do
      opts = Keyword.merge(@default_options, opts)
      http_client = Keyword.get(opts, :http_client, Req)
      scraping_bee = Keyword.get(opts, :scraping_bee)
      proxy = Keyword.get(opts, :proxy)

      u_topic = String.upcase(topic)
      url = if u_topic in @headlines,
        do: "/headlines/section/topic/#{u_topic}?",
        else: "/topics/#{topic}?"

      data = parse_feed(
        @base_url <> url <> ceid(opts),
        proxy,
        scraping_bee,
        http_client
      )
      data = %{data | entries: add_sub_articles data.entries }

      if Enum.empty?(data.entries), do: throw "Unsupported topic"

      {:ok, data}
    catch _, reason -> {:error, reason}
    end
  end

  @spec topic_headlines!(String.t, list) :: parsed_feed
  def topic_headlines!(geo, opts \\ []) when is_binary(geo) and is_list(opts) do
    topic_headlines(geo, opts) |> Unsafe.Handler.bang!
  end

  @doc """
  Return a list of all articles about a specific geolocation given a country and a language.
  """
  @spec geo_headlines(String.t, list) :: {:ok, parsed_feed} | {:error, term}
  def geo_headlines(geo, opts \\ []) when is_binary(geo) and is_list(opts) do
    try do
      opts = Keyword.merge(@default_options, opts)
      http_client = Keyword.get(opts, :http_client, Req)
      scraping_bee = Keyword.get(opts, :scraping_bee)
      proxy = Keyword.get(opts, :proxy)

      data = parse_feed(
        @base_url <> "/headlines/section/geo/#{geo}?" <> ceid(opts),
        proxy,
        scraping_bee,
        http_client
      )
      data = %{data | entries: add_sub_articles data.entries }

      {:ok, data}
    catch _, reason -> {:error, reason}
    end
  end

  @spec geo_headlines!(String.t, list) :: parsed_feed
  def geo_headlines!(geo, opts \\ []) when is_binary(geo) and is_list(opts) do
    geo_headlines(geo, opts) |> Unsafe.Handler.bang!
  end

  @doc """
  Return a list of all articles given a full-text search parameter, a country and a language.

  @param boolean helper: When True helps with URL quoting.
  @param binary when: Sets a time range for the artiles that can be found.
  """
  @spec search(String.t, list) :: {:ok, parsed_feed} | {:error, term}
  def search(query, opts \\ []) when is_binary(query) and is_list(opts) do
    try do
      opts = Keyword.merge(@default_options, opts)
      http_client = Keyword.get(opts, :http_client, Req)
      scraping_bee = Keyword.get(opts, :scraping_bee)
      proxy = Keyword.get(opts, :proxy)

      query = process_query(
        query,
        Keyword.get(opts, :helper, true),
        Keyword.get(opts, :when),
        Keyword.get(opts, :from),
        Keyword.get(opts, :to)
      )

      data = parse_feed(
        @base_url <> "/search?q=#{query}&" <> ceid(opts),
        proxy,
        scraping_bee,
        http_client
      )
      data = %{data | entries: add_sub_articles data.entries }

      {:ok, data}
    catch _, reason -> {:error, reason}
    end
  end

  @spec search!(String.t, list) :: parsed_feed
  def search!(query, opts \\ []) when is_binary(query) and is_list(opts) do
    search(query, opts) |> Unsafe.Handler.bang!
  end

end
