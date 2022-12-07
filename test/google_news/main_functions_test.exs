defmodule GoogleNews.MainFunctionsTest do
  use ExUnit.Case
  doctest GoogleNews

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  @url_top_news "#{@base_url}?#{@ceid_en_us}"
  @url_topic_headlines "#{@base_url}/headlines/section/topic/SPORTS?#{@ceid_en_us}"
  @url_geo_headlines "#{@base_url}/headlines/section/geo/Los%20Angeles?#{@ceid_en_us}"
  @url_search "#{@base_url}/search?q=boeing+after%3A2022-02-24&#{@ceid_en_us}"

  test "error on 404 for top_news" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_top_news
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
      assert url == @url_top_news
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
    assert Enum.count(entries) == 37

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == GoogleNews.Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == GoogleNews.SubArticle
      end)
    end)
  end

  test "error on 404 for topic_headlines" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_topic_headlines
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
      assert url == @url_topic_headlines
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
    assert Enum.count(entries) == 70

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == GoogleNews.Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == GoogleNews.SubArticle
      end)
    end)
  end

  test "error on 404 for geo_headlines" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_geo_headlines
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
      assert url == @url_geo_headlines
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
    assert Enum.count(entries) == 63

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
      assert url == @url_search
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
      assert url == @url_search
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
    assert Enum.count(entries) == 97

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == GoogleNews.Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == GoogleNews.SubArticle
      end)
    end)
  end
end
