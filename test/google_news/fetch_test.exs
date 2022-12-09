defmodule GoogleNews.FetchTest do
  use ExUnit.Case, async: true

  alias GoogleNews.{Feed, FeedInfo, Entry}
  alias GoogleNews.{Fetch, Parse}
  alias GoogleNews.{FetchError, ParseError}

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  test "error on fetch, reason: :invalid_uri" do
    error = %FetchError{
      reason: :invalid_uri,
      value: "https://example.com/rss"
    }

    result =
      try do
        Fetch.fetch!("https://example.com/rss")
      rescue
        err in [FetchError, ArgumentError] -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :request_error" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}?#{@ceid_en_us}"
      assert opts == []

      {:error, :foo_bar}
    end)

    error = %FetchError{
      reason: :request_error,
      value: :foo_bar
    }

    result =
      try do
        Fetch.fetch!("")
      rescue
        err in [FetchError, ArgumentError] -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :response_status (building url 1)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "http://news.google.com/rss/example?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        Fetch.fetch!("http://news.google.com/rss/example")
      rescue
        err in [FetchError, ArgumentError] -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :response_status (building url 2)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example/foo?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        Fetch.fetch!("example/foo")
      rescue
        err in [FetchError, ArgumentError] -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :response_status (building url 3)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example/bar?#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        Fetch.fetch!("rss/example/bar")
      rescue
        err in [FetchError, ArgumentError] -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :response_status (building url 4)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == "#{@base_url}/example?foo=42&bar=test&ex=foo%3Abar&#{@ceid_en_us}"
      assert opts == []

      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        Fetch.fetch!("example?foo=42&bar=test&ex=foo:bar")
      rescue
        err in [FetchError, ArgumentError] -> err
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
        "foo/bar"
        |> Fetch.fetch!()
        |> Parse.parse!()
      rescue
        err in [FetchError, ParseError, ArgumentError] -> err
      end

    assert result.__struct__ == Feed

    %Feed{feed: feed, entries: entries} = result

    assert feed.__struct__ == FeedInfo
    assert feed.title == "Google News"
    assert Enum.count(entries) == 1

    entry = Enum.at(entries, 0)

    assert entry.__struct__ == Entry
    assert entry.title == "This feed is not available."
  end
end
