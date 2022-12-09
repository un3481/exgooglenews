defmodule GoogleNews.MainTest do
  use ExUnit.Case, async: true
  import Mox

  alias GoogleNews.{Feed, FeedInfo, Entry, SubArticle}
  alias GoogleNews.FetchError

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  @url_top_news "#{@base_url}?#{@ceid_en_us}"
  @url_topic_headlines "#{@base_url}/headlines/section/topic/SPORTS?#{@ceid_en_us}"
  @url_geo_headlines "#{@base_url}/headlines/section/geo/Los%20Angeles?#{@ceid_en_us}"
  @url_search "#{@base_url}/search?q=boeing+after%3A2022-02-24&#{@ceid_en_us}"

  test "error on top_news, reason: :response_status" do
    ReqMock
    |> expect(:get, fn @url_top_news, [] ->
      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    assert {:error, error} == GoogleNews.top_news()
  end

  test "ok on top_news" do
    ReqMock
    |> expect(:get, fn @url_top_news, [] ->
      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/top_news.rss")
       }}
    end)

    {:ok, %Feed{feed: feed, entries: entries}} = GoogleNews.top_news()

    assert feed.__struct__ == FeedInfo
    assert feed.title == "Top stories - Google News"
    assert Enum.count(entries) == 37

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == SubArticle
      end)
    end)
  end

  test "error on topic_headlines, reason: :response_status" do
    ReqMock
    |> expect(:get, fn @url_topic_headlines, [] ->
      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    assert {:error, error} == GoogleNews.topic_headlines("Sports")
  end

  test "ok on topic_headlines" do
    ReqMock
    |> expect(:get, fn @url_topic_headlines, [] ->
      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/topic_headlines.rss")
       }}
    end)

    {:ok, %Feed{feed: feed, entries: entries}} = GoogleNews.topic_headlines("Sports")

    assert feed.__struct__ == FeedInfo
    assert feed.title == "Sports - Latest - Google News"
    assert Enum.count(entries) == 70

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == SubArticle
      end)
    end)
  end

  test "error on geo_headlines, reason: :response_status" do
    ReqMock
    |> expect(:get, fn @url_geo_headlines, [] ->
      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    assert {:error, error} == GoogleNews.geo_headlines("Los Angeles")
  end

  test "ok on geo_headlines" do
    ReqMock
    |> expect(:get, fn @url_geo_headlines, [] ->
      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/geo_headlines.rss")
       }}
    end)

    {:ok, %Feed{feed: feed, entries: entries}} = GoogleNews.geo_headlines("Los Angeles")

    assert feed.__struct__ == FeedInfo
    assert feed.title == "Los Angeles - Latest - Google News"
    assert Enum.count(entries) == 63

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == SubArticle
      end)
    end)
  end

  test "error on search, reason: :argument_error (invalid argument type)" do
    error = %ArgumentError{
      message: "cannot parse ~D[2022-02-24] as date, reason: :invalid_format"
    }

    assert {:error, error} == GoogleNews.search("boeing", from: ~D[2022-02-24])
  end

  test "error on search, reason: :argument_error (invalid date format)" do
    error = %ArgumentError{
      message: "cannot parse \"2022-02\" as date, reason: :invalid_format"
    }

    assert {:error, error} == GoogleNews.search("boeing", from: "2022-02")
  end

  test "error on search, reason: :response_status" do
    ReqMock
    |> expect(:get, fn @url_search, [] ->
      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    assert {:error, error} == GoogleNews.search("boeing", from: "2022-02-24")
  end

  test "ok on search" do
    ReqMock
    |> expect(:get, fn @url_search, [] ->
      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/search.rss")
       }}
    end)

    {:ok, %Feed{feed: feed, entries: entries}} = GoogleNews.search("boeing", from: "2022-02-24")

    assert feed.__struct__ == FeedInfo
    assert feed.title == "\"boeing after:2022-02-24\" - Google News"
    assert Enum.count(entries) == 97

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == Entry

      Enum.each(entry.sub_articles, fn sub_article ->
        assert sub_article.__struct__ == SubArticle
      end)
    end)
  end
end
