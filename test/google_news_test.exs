defmodule GoogleNewsTest do
  use ExUnit.Case
  doctest GoogleNews

  @scraping_bee_url "https://app.scrapingbee.com/api/v1/"
  @top_news_url "https://news.google.com/rss?ceid=US:en&hl=en&gl=US"
  @boeing_search_url "https://news.google.com/rss/search?q=boeing%20after:2022-02-24&ceid=US:en&hl=en&gl=US"

  @example_proxy {:http, "localhost", 8899, []}
  @example_scraping_bee_token "123456789abc"

  test "error on argument to proxy & scraping_bee" do
    error = %ArgumentError{
      message: "Pick either a proxy or ScrapingBee. Not both!"
    }

    assert {:error, error} == GoogleNews.top_news(proxy: @example_proxy, scraping_bee: @example_scraping_bee_token)
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

  test "error on 404 & build query" do
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

  test "ok on 200 for top_news" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert @top_news_url == url
      assert [] == opts

      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/top_news.rss")
       }}
    end)

    {:ok, %{feed: feed, entries: entries}} = GoogleNews.top_news()

    assert feed.__struct__ == FeederEx.Feed
    assert feed.title == "Top stories - Google News"

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == FeederEx.Entry
    end)
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
      assert opts == [json: %{api_key: @example_scraping_bee_token, render_js: "false", url: @top_news_url}]

      {:ok, %Req.Response{status: 404, body: :scraping_bee}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404, body: :scraping_bee}
    }

    assert {:error, error} == GoogleNews.top_news(scraping_bee: @example_scraping_bee_token)
  end

  test "error on argument to search query" do
    error = %ArgumentError{
      message: "cannot parse ~D[2022-02-24] as date, reason: :invalid_format"
    }

    assert {:error, error} == GoogleNews.search("boeing", from: ~D[2022-02-24])
  end

  test "error on 404 & build search query" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @boeing_search_url
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
      assert url == @boeing_search_url
      assert opts == []

      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/search-boeing-from20220224.rss")
       }}
    end)

    {:ok, %{feed: feed, entries: entries}} = GoogleNews.search("boeing", from: "2022-02-24")

    assert feed.__struct__ == FeederEx.Feed
    assert feed.title == "\"boeing after:2022-02-24\" - Google News"

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == FeederEx.Entry
    end)
  end
end
