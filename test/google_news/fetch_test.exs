defmodule GoogleNews.FetchTest do
  use ExUnit.Case, async: true
  import Mox

  alias GoogleNews.Fetch
  alias GoogleNews.FetchError

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  test "error on fetch, reason: :argument_error (invalid uri host)" do
    error = %ArgumentError{
      message: "invalid uri host: \"example.com\""
    }

    result =
      try do
        Fetch.fetch!("https://example.com/rss")
      rescue
        err in ArgumentError -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :request_error" do
    ReqMock
    |> expect(:get, fn "#{@base_url}/foo?#{@ceid_en_us}", [] ->
      {:error, :test}
    end)

    error = %FetchError{
      reason: :request_error,
      value: :test
    }

    result =
      try do
        Fetch.fetch!("foo")
      rescue
        err in FetchError -> err
      end

    assert error == result
  end

  test "error on fetch, reason: :response_status" do
    ReqMock
    |> expect(:get, fn "#{@base_url}/foo/bar?#{@ceid_en_us}", [] ->
      {:ok, %Req.Response{status: 404}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404}
    }

    result =
      try do
        Fetch.fetch!("foo/bar")
      rescue
        err in FetchError -> err
      end

    assert error == result
  end

  test "ok on fetch (building url 1)" do
    ReqMock
    |> expect(:get, fn "http://news.google.com/rss/example?#{@ceid_en_us}", [] ->
      {:ok, %Req.Response{status: 200, body: "<rss></rss>"}}
    end)

    result = Fetch.fetch!("http://news.google.com/rss/example")

    assert result == "<rss></rss>"
  end

  test "ok on fetch (building url 2)" do
    ReqMock
    |> expect(:get, fn "#{@base_url}/example/foo?#{@ceid_en_us}", [] ->
      {:ok, %Req.Response{status: 200, body: "<rss></rss>"}}
    end)

    result = Fetch.fetch!("example/foo")

    assert result == "<rss></rss>"
  end

  test "ok on fetch (building url 3)" do
    ReqMock
    |> expect(:get, fn "#{@base_url}/example/bar?#{@ceid_en_us}", [] ->
      {:ok, %Req.Response{status: 200, body: "<rss></rss>"}}
    end)

    result = Fetch.fetch!("rss/example/bar")

    assert result == "<rss></rss>"
  end

  test "ok on fetch (building url 4)" do
    ReqMock
    |> expect(
      :get,
      fn "#{@base_url}/example?foo=42&bar=test&ex=foo%3Abar&#{@ceid_en_us}", [] ->
        {:ok, %Req.Response{status: 200, body: "<rss></rss>"}}
      end
    )

    result = Fetch.fetch!("example?foo=42&bar=test&ex=foo:bar")

    assert result == "<rss></rss>"
  end

  test "ok on fetch (custom language)" do
    ReqMock
    |> expect(:get, fn "#{@base_url}/example?ceid=UA%3Auk&hl=uk&gl=UA", [] ->
      {:ok, %Req.Response{status: 200, body: "<rss></rss>"}}
    end)

    result = Fetch.fetch!("rss/example", lang: "uk", country: "UA")

    assert result == "<rss></rss>"
  end
end
