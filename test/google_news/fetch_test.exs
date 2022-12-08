defmodule GoogleNews.FetchTest do
  use ExUnit.Case
  doctest GoogleNews

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  test "error on fetch, reason: :invalid_uri" do
    error = %GoogleNews.FetchError{
      reason: :invalid_uri,
      value: "https://example.com/rss"
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("https://example.com/rss")
      rescue
        err -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :request_error" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}?#{@ceid_en_us}"
      assert opts == []

      {:error, :foo_bar}
    end)

    error = %GoogleNews.FetchError{
      reason: :request_error,
      value: :foo_bar
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("")
      rescue
        err -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :http_status (building url 1)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "http://news.google.com/rss/example?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      reason: :http_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("http://news.google.com/rss/example")
      rescue
        err -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :http_status (building url 2)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example/foo?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      reason: :http_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("example/foo")
      rescue
        err -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :http_status (building url 3)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example/bar?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      reason: :http_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("rss/example/bar")
      rescue
        err -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :http_status (building url 4)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example?foo=42&bar=test&ex=foo%3Abar&#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %GoogleNews.FetchError{
      reason: :http_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        GoogleNews.Fetch.fetch!("example?foo=42&bar=test&ex=foo:bar")
      rescue
        err -> err
      end

    assert error == result
  end

  test "ok on fetch (fetching non-existent feed)" do
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
        _ -> :error
      end

    assert result != :error

    feed =
      try do
        GoogleNews.Parse.parse!(result)
      rescue
        _ -> :error
      end

    assert feed != :error

    %GoogleNews.Feed{feed: feed, entries: entries} = feed

    assert feed.__struct__ == GoogleNews.FeedInfo
    assert feed.title == "Google News"
    assert Enum.count(entries) == 1

    entry = Enum.at(entries, 0)

    assert entry.__struct__ == GoogleNews.Entry
    assert entry.title == "This feed is not available."
  end
end
