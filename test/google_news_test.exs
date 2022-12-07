defmodule GoogleNewsTest do
  use ExUnit.Case
  doctest GoogleNews

  @example_proxy {:http, "localhost", 8899, []}
  @example_scraping_bee_token "123456789abc"
  @scraping_bee_url "https://app.scrapingbee.com/api/v1/"

  @top_news_url "https://news.google.com/rss?ceid=US%3Aen&hl=en&gl=US"
  @topic_headlines_url "https://news.google.com/rss/headlines/section/topic/SPORTS?ceid=US%3Aen&hl=en&gl=US"
  @geo_headlines_url "https://news.google.com/rss/headlines/section/geo/Los%20Angeles?ceid=US%3Aen&hl=en&gl=US"
  @search_url "https://news.google.com/rss/search?q=boeing+after%3A2022-02-24&ceid=US%3Aen&hl=en&gl=US"

  test "error on using both proxy & scraping_bee" do
    error = %ArgumentError{
      message: "pick either a proxy or scraping_bee, not both"
    }

    assert {:error, error} ==
             GoogleNews.top_news(proxy: @example_proxy, scraping_bee: @example_scraping_bee_token)
  end

  test "error on Req" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @top_news_url
      assert opts == []

      {:error, :req_error}
    end)

    error = %GoogleNews.FetchError{value: :req_error}

    assert {:error, error} == GoogleNews.top_news()
  end

  test "error on invalid RSS" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @top_news_url
      assert opts == []

      {:ok, %Req.Response{status: 200, body: ""}}
    end)

    error = %GoogleNews.ParseError{
      message: 'Can\'t detect character encoding due to lack of indata'
    }

    assert {:error, error} == GoogleNews.top_news()
  end

  test "error on 404 for top_news" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @top_news_url
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404}
    }

    assert {:error, error} == GoogleNews.top_news()
  end

  test "error on 404 for top_news using proxy" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @top_news_url
      assert opts == [connect_options: [proxy: @example_proxy]]

      {:ok, %Req.Response{status: 404, body: :proxy}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404, body: :proxy}
    }

    assert {:error, error} == GoogleNews.top_news(proxy: @example_proxy)
  end

  test "error on 404 for top_news using scraping bee" do
    Mox.expect(ReqMock, :post, fn url, opts ->
      assert url == @scraping_bee_url

      assert opts == [
               json: %{
                 api_key: @example_scraping_bee_token,
                 render_js: "false",
                 url: @top_news_url
               }
             ]

      {:ok, %Req.Response{status: 404, body: :scraping_bee}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404, body: :scraping_bee}
    }

    assert {:error, error} == GoogleNews.top_news(scraping_bee: @example_scraping_bee_token)
  end

  test "ok on 200 for top_news" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @top_news_url
      assert opts == []

      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/top_news.rss")
       }}
    end)

    {:ok, %GoogleNews.Feed{feed: feed, entries: entries}} = GoogleNews.top_news()

    assert feed.__struct__ == GoogleNews.FeedInfo
    assert feed.title == "Top stories - Google News"

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == GoogleNews.Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == GoogleNews.SubArticle
      end)
    end)
  end

  test "error on 404 for topic_headlines" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @topic_headlines_url
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404}
    }

    assert {:error, error} == GoogleNews.topic_headlines("Sports")
  end

  test "ok on 200 for topic_headlines" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @topic_headlines_url
      assert opts == []

      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/topic_headlines.rss")
       }}
    end)

    {:ok, %GoogleNews.Feed{feed: feed, entries: entries}} = GoogleNews.topic_headlines("Sports")

    assert feed.__struct__ == GoogleNews.FeedInfo
    assert feed.title == "Sports - Latest - Google News"

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == GoogleNews.Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == GoogleNews.SubArticle
      end)
    end)
  end

  test "error on 404 for geo_headlines" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @geo_headlines_url
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404}
    }

    assert {:error, error} == GoogleNews.geo_headlines("Los Angeles")
  end

  test "ok on 200 for geo_headlines" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @geo_headlines_url
      assert opts == []

      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/geo_headlines.rss")
       }}
    end)

    {:ok, %GoogleNews.Feed{feed: feed, entries: entries}} =
      GoogleNews.geo_headlines("Los Angeles")

    assert feed.__struct__ == GoogleNews.FeedInfo
    assert feed.title == "Los Angeles - Latest - Google News"

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == GoogleNews.Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == GoogleNews.SubArticle
      end)
    end)
  end

  test "error on argument to search" do
    error = %ArgumentError{
      message: "cannot parse ~D[2022-02-24] as date, reason: :invalid_format"
    }

    assert {:error, error} == GoogleNews.search("boeing", from: ~D[2022-02-24])
  end

  test "error on 404 for search" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @search_url
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404}
    }

    assert {:error, error} == GoogleNews.search("boeing", from: "2022-02-24")
  end

  test "ok on 200 for search" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @search_url
      assert opts == []

      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/search.rss")
       }}
    end)

    {:ok, %GoogleNews.Feed{feed: feed, entries: entries}} =
      GoogleNews.search("boeing", from: "2022-02-24")

    assert feed.__struct__ == GoogleNews.FeedInfo
    assert feed.title == "\"boeing after:2022-02-24\" - Google News"

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == GoogleNews.Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == GoogleNews.SubArticle
      end)
    end)
  end
end
