defmodule Googlenews do
  @moduledoc """
  Documentation for `Googlenews`.
  """

  @base_url "https://news.google.com/rss"

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

  # @unsupported "https://news.google.com/rss/unsupported"

  #
  # Compile correct country-lang parameters for Google News RSS URL
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
        |> Timex.parse!("%Y-%m-%d", :strftime)
        |> Timex.format!("%Y-%m-%d", :strftime)
    catch _, _ -> throw "Could not parse your date"
    end
  end

  #
  # Return subarticles from the main and topic feeds
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
  # Retrieve RSS Feed using provided methods
  #
  defp get_feed(_, proxies, scraping_bee) when
    not is_nil(proxies) and
    not is_nil(scraping_bee)
  do
    throw "Pick either ScrapingBee or proxies. Not both!"
  end

  defp get_feed(feed_url, proxies, _) when
    is_binary(feed_url) and
    is_map(proxies)
  do
    scheme = cond do
      String.contains? feed_url, "http://" -> :http
      String.contains? feed_url, "https://" -> :https
      true -> :http
    end
    proxy = Map.get proxies, scheme

    Req.get! feed_url, connect_options: [proxy: proxy]
  end

  defp get_feed(feed_url, _, scraping_bee) when
    is_binary(feed_url) and
    is_binary(scraping_bee)
  do
    Req.post!(
      "https://app.scrapingbee.com/api/v1/",
      json: %{
        url: feed_url,
        api_key: scraping_bee,
        render_js: "false"
      }
    )
  end

  defp get_feed(feed_url, _, _) when is_binary(feed_url) do
    Req.get! feed_url
  end

  #
  # Check response for RSS Feed
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
  # Retrieve and process RSS Feed
  #
  defp parse_feed(
    feed_url,
    proxies,
    scraping_bee
  ) do
    feed_url
      |> get_feed(proxies, scraping_bee)
      |> check_response
      |> FeederEx.parse
      |> format_map
  end

  @doc """
  Return a list of all articles from the main page of Google News given a country and a language
  """
  def top_news(
    proxies \\ nil,
    scraping_bee \\ nil,
    opts \\ []
  ) when
    is_list(opts)
  do
    try do
      opts = Keyword.merge(@default_options, opts)

      data = parse_feed(
        @base_url <> "?" <> ceid(opts),
        proxies,
        scraping_bee
      )
      data = %{data | entries: add_sub_articles data.entries }

      {:ok, data}
    catch _, reason -> {:error, reason}
    end
  end

  @doc """
  Return a list of all articles from the topic page of Google News given a country and a language
  """
  def topic_headlines(
    topic,
    proxies \\ nil,
    scraping_bee \\ nil,
    opts \\ []
  ) when
    is_binary(topic) and
    is_list(opts)
  do
    try do
      opts = Keyword.merge(@default_options, opts)

      u_topic = String.upcase(topic)
      url = if u_topic in @headlines,
        do: "/headlines/section/topic/#{u_topic}?",
        else: "/topics/#{topic}?"

      data = parse_feed(
        @base_url <> url <> ceid(opts),
        proxies,
        scraping_bee
      )
      data = %{data | entries: add_sub_articles data.entries }

      if Enum.empty?(data.entries), do: throw "Unsupported topic"

      {:ok, data}
    catch _, reason -> {:error, reason}
    end
  end

  @doc """
  Return a list of all articles about a specific geolocation given a country and a language
  """
  def geo_headlines(
    geo,
    proxies \\ nil,
    scraping_bee \\ nil,
    opts \\ []
  ) when
    is_binary(geo) and
    is_list(opts)
  do
    try do
      opts = Keyword.merge(@default_options, opts)

      data = parse_feed(
        @base_url <> "/headlines/section/geo/#{geo}?" <> ceid(opts),
        proxies,
        scraping_bee
      )
      data = %{data | entries: add_sub_articles data.entries }

      {:ok, data}
    catch _, reason -> {:error, reason}
    end
  end

  @doc """
  Return a list of all articles given a full-text search parameter, a country and a language

  @param boolean helper: When True helps with URL quoting
  @param binary when: Sets a time range for the artiles that can be found
  """
  def search(
    query,
    helper \\ true,
    when_ \\ nil,
    from \\ nil,
    to \\ nil,
    proxies \\ nil,
    scraping_bee \\ nil,
    opts \\ []
  )

  def search(query, helper, when_, _, _, proxies, scraping_bee, opts) when is_binary(when_) do
    search(query <> " when:" <> when_, helper, nil, nil, nil, proxies, scraping_bee, opts)
  end

  def search(query, helper, _, from, to, proxies, scraping_bee, opts) when is_binary(from) do
    search(query <> " after:" <> from_to_helper(from), helper, nil, nil, to, proxies, scraping_bee, opts)
  end

  def search(query, helper, _, _, to, proxies, scraping_bee, opts) when is_binary(to) do
    search(query <> " before:" <> from_to_helper(to), helper, nil, nil, nil, proxies, scraping_bee, opts)
  end

  def search(query, helper, _, _, _, proxies, scraping_bee, opts) when helper do
    search(search_helper(query), false, nil, nil, nil, proxies, scraping_bee, opts)
  end

  def search(query, _, _, _, _, proxies, scraping_bee, opts) when
    is_binary(query) and
    is_list(opts)
  do
    try do
      opts = Keyword.merge(@default_options, opts)

      data = parse_feed(
        @base_url <> "/search?q=#{query}&" <> ceid(opts),
        proxies,
        scraping_bee
      )
      data = %{data | entries: add_sub_articles data.entries }

      {:ok, data}
    catch _, reason -> {:error, reason}
    end
  end

end
