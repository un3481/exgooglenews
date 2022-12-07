defmodule GoogleNews.ParseTest do
  use ExUnit.Case
  doctest GoogleNews

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  @url_top_news "#{@base_url}?#{@ceid_en_us}"

  test "error on invalid RSS for top_news (1)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_top_news
      assert opts == []

      {:ok, %Req.Response{status: 200, body: ""}}
    end)

    error = %GoogleNews.ParseError{
      message: 'Can\'t detect character encoding due to lack of indata'
    }

    assert {:error, error} == GoogleNews.top_news()
  end

  test "error on invalid RSS for top_news (2)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_top_news
      assert opts == []

      {:ok, %Req.Response{status: 200, body: "<rss bff65"}}
    end)

    error = %GoogleNews.ParseError{
      message: 'Continuation function undefined'
    }

    assert {:error, error} == GoogleNews.top_news()
  end

  test "error on invalid RSS for top_news (3)" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_top_news
      assert opts == []

      {:ok,
       %Req.Response{
         status: 200,
         body: "<rss version=\\\"2.0\\\"></rss>"
       }}
    end)

    error = %GoogleNews.ParseError{
      message: '\', " or whitespace expected'
    }

    assert {:error, error} == GoogleNews.top_news()
  end

  test "ok on 200 for top_news with empty RSS" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_top_news
      assert opts == []

      {:ok,
       %Req.Response{
         status: 200,
         body: "<rss version=\"2.0\"></rss>"
       }}
    end)

    assert {:ok, %GoogleNews.Feed{}} == GoogleNews.top_news()
  end
end
