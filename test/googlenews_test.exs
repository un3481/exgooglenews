defmodule GooglenewsTest do
  use ExUnit.Case
  doctest Googlenews

  test "error on 404" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{status: 404}
    end)

    reason = %{status: 404, body: ""}

    assert {:error, reason} == Googlenews.top_news()
  end

  test "error on invalid RSS" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{status: 200, body: ""}
    end)

    reason = 'Can\'t detect character encoding due to lack of indata'

    assert {:error, reason} == Googlenews.top_news()
  end

  test "ok on 200" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{
        status: 200,
        body: File.read!("test/documents/top_news.rss")
      }
    end)

    {:ok, %{feed: feed, entries: entries}} = Googlenews.top_news()

    assert feed.__struct__ == FeederEx.Feed

    entries
    |> Enum.each(fn entry ->
      assert entry.__struct__ == FeederEx.Entry
    end)
  end

  test "build of search query" do
    Mox.expect(ReqMock, :get!, fn url, _ ->
      %Req.Response{status: 404, body: url}
    end)

    expected_url =
      "https://news.google.com/rss/search?q=boeing%20after:2022-02-24&ceid=US:en&hl=en&gl=US"

    reason = %{status: 404, body: expected_url}

    assert {:error, reason} == Googlenews.search("boeing", from: "2022-02-24")
  end

  test "ok on 200 /search" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{
        status: 200,
        body: File.read!("test/documents/search-boeing-from20220224.rss")
      }
    end)

    {:ok, %{feed: feed, entries: entries}} = Googlenews.search("boeing", from: "2022-02-24")

    assert feed.__struct__ == FeederEx.Feed

    entries
    |> Enum.each(fn entry ->
      assert entry.__struct__ == FeederEx.Entry
    end)
  end
end
