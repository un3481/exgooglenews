defmodule GoogleNews.ProxyTest do
  use ExUnit.Case
  doctest GoogleNews

  @base_url "https://news.google.com/rss"
  @ceid_en_us "ceid=US%3Aen&hl=en&gl=US"

  @url_top_news "#{@base_url}?#{@ceid_en_us}"

  @example_proxy {:http, "localhost", 8899, []}
  @example_scraping_bee_token "123456789abc"
  @scraping_bee_url "https://app.scrapingbee.com/api/v1/"

  test "error on using both proxy & scraping_bee" do
    error = %ArgumentError{
      message: "pick either a proxy or scraping_bee, not both"
    }

    assert {:error, error} ==
             GoogleNews.top_news(
               proxy: @example_proxy,
               scraping_bee: @example_scraping_bee_token
             )
  end

  test "error on 404 for top_news using proxy" do
    Mox.expect(ReqMock, :get, fn url, opts ->
      assert url == @url_top_news
      assert opts == [connect_options: [proxy: @example_proxy]]

      {:ok, %Req.Response{status: 404, body: :proxy}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404, body: :proxy}
    }

    assert {:error, error} == GoogleNews.top_news(proxy: @example_proxy)
  end

  test "error on 404 for top_news using scraping bee" do
    Mox.expect(ReqMock, :post, fn url, opts ->
      assert url == @scraping_bee_url

      assert opts == [
               json: %{
                 api_key: @example_scraping_bee_token,
                 render_js: "false",
                 url: @url_top_news
               }
             ]

      {:ok, %Req.Response{status: 404, body: :scraping_bee}}
    end)

    error = %GoogleNews.FetchError{
      value: %Req.Response{status: 404, body: :scraping_bee}
    }

    assert {:error, error} == GoogleNews.top_news(scraping_bee: @example_scraping_bee_token)
  end
end
