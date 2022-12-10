defmodule GoogleNews.ProxyTest do
  use ExUnit.Case, async: true
  import Mox

  alias GoogleNews.FetchError

  @url_scraping_bee "https://app.scrapingbee.com/api/v1/"
  @example_scraping_bee_token "123456789abc"
  @example_proxy {:http, "localhost", 8899, []}

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  @url_top_news "#{@base_url}?#{@ceid_en_us}"

  test "error on top_news, reason: :argument_error (using both :proxy and :scraping_bee)" do
    options = [
      proxy: @example_proxy,
      scraping_bee: @example_scraping_bee_token
    ]

    error = %ArgumentError{
      message: "use either :proxy or :scraping_bee, not both"
    }

    assert {:error, error} == GoogleNews.top_news(options)
  end

  test "error on top_news, reason: :argument_error (invalid :proxy)" do
    error = %ArgumentError{
      message: "invalid proxy: \"http://localhost:8899\""
    }

    assert {:error, error} == GoogleNews.top_news(proxy: "http://localhost:8899")
  end

  test "error on top_news, reason: :response_status (using :proxy)" do
    ReqMock
    |> expect(:get, fn @url_top_news, [connect_options: [proxy: @example_proxy]] ->
      {:ok, %Req.Response{status: 404, body: "proxy test"}}
    end)

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404, body: "proxy test"}
    }

    assert {:error, error} == GoogleNews.top_news(proxy: @example_proxy)
  end

  test "error on top_news, reason: :argument_error (invalid :scraping_bee)" do
    error = %ArgumentError{
      message: "invalid scraping_bee token: 1234"
    }

    assert {:error, error} == GoogleNews.top_news(scraping_bee: 1234)
  end

  test "error on top_news, reason: :response_status (using :scraping_bee)" do
    ReqMock
    |> expect(
      :post,
      fn @url_scraping_bee,
         [
           json: %{
             api_key: @example_scraping_bee_token,
             render_js: "false",
             url: @url_top_news
           }
         ] ->
        {:ok, %Req.Response{status: 404, body: "scraping_bee test"}}
      end
    )

    error = %FetchError{
      reason: :response_status,
      value: %Req.Response{status: 404, body: "scraping_bee test"}
    }

    assert {:error, error} == GoogleNews.top_news(scraping_bee: @example_scraping_bee_token)
  end
end
