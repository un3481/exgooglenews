defmodule GooglenewsTest do
  use ExUnit.Case
  doctest Googlenews

  test "error on invalid RSS" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{status: 200, body: ""}
    end)

    reason = 'Can\'t detect character encoding due to lack of indata'

    assert {:error, reason} == Googlenews.top_news()
  end

  test "error on 404 & build query" do
    Mox.expect(ReqMock, :get!, fn url, _ ->
      %Req.Response{
        status: 404,
        body: "requested url: " <> url
      }
    end)

    reason = %{
      status: 404,
      body:
        "requested url: " <>
          "https://news.google.com/rss?ceid=US:en&hl=en&gl=US"
    }

    assert {:error, reason} == Googlenews.top_news()
  end

  test "ok on 200 for top_news" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{
        status: 200,
        body: File.read!("test/documents/top_news.rss")
      }
    end)

    {:ok, %{feed: feed, entries: entries}} = Googlenews.top_news()

    assert feed.__struct__ == FeederEx.Feed
    assert feed.title == "Top stories - Google News"

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == FeederEx.Entry
    end)
  end

  test "error on 404 & build search query" do
    Mox.expect(ReqMock, :get!, fn url, _ ->
      %Req.Response{
        status: 404,
        body: "requested url: " <> url
      }
    end)

    reason = %{
      status: 404,
      body:
        "requested url: " <>
          "https://news.google.com/rss/search?q=boeing%20after:2022-02-24&ceid=US:en&hl=en&gl=US"
    }

    assert {:error, reason} == Googlenews.search("boeing", from: "2022-02-24")
  end

  test "ok on 200 for search" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{
        status: 200,
        body: File.read!("test/documents/search-boeing-from20220224.rss")
      }
    end)

    {:ok, %{feed: feed, entries: entries}} = Googlenews.search("boeing", from: "2022-02-24")

    assert feed.__struct__ == FeederEx.Feed
    assert feed.title == "\"boeing after:2022-02-24\" - Google News"

    Enum.each(entries, fn entry ->
      assert entry.__struct__ == FeederEx.Entry
    end)
  end
end
