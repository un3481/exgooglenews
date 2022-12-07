defmodule GoogleNews.FetchTest do
  use ExUnit.Case
  doctest GoogleNews

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  @url_top_news "#{@base_url}?#{@ceid_en_us}"

  test "error on Req" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_top_news
      assert opts == []

      {:error, :req_error}
    end)

    error = %GoogleNews.FetchError{value: :req_error}

    assert {:error, error} == GoogleNews.top_news()
  end

  test "error on fetch invalid url" do
    error = %ArgumentError{message: "invalid uri"}

    result =
      try do
        {:ok, GoogleNews.Fetch.fetch!("https://example.com/rss")}
      rescue
        e -> {:error, e}
      end

    assert {:error, error} == result
  end

  test "error on 404 for fetch (1)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "http://news.google.com/rss/example?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404}
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("http://news.google.com/rss/example")
      rescue
        e -> {:error, e}
      end

    assert {:error, error} == result
  end

  test "error on 404 for fetch (2)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example/foo?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404}
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("example/foo")
      rescue
        e -> {:error, e}
      end

    assert {:error, error} == result
  end

  test "error on 404 for fetch (3)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example/bar?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404}
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("rss/example/bar")
      rescue
        e -> {:error, e}
      end

    assert {:error, error} == result
  end

  test "error on 404 for fetch (4)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example?foo=42&bar=test&ex=foo%3Abar&#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404}
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("example?foo=42&bar=test&ex=foo:bar")
      rescue
        e -> {:error, e}
      end

    assert {:error, error} == result
  end

  test "ok on 200 for fetch non-existent feed" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/foo/bar?#{@ceid_en_us}"
      assert opts == []

      {:ok,
       %Req.Response{
         status: 200,
         body: File.read!("test/documents/not_found.rss")
       }}
    end)

    result =
      try do
        GoogleNews.Fetch.fetch!("foo/bar")
      rescue
        _ -> nil
      end

    assert result != nil

    %GoogleNews.Feed{feed: feed, entries: entries} = GoogleNews.Parse.parse!(result)

    assert feed.__struct__ == GoogleNews.FeedInfo
    assert feed.title == "Google News"
    assert Enum.count(entries) == 1

    entry = Enum.at(entries, 0)

    assert entry.__struct__ == GoogleNews.Entry
    assert entry.title == "This feed is not available."
  end
end
