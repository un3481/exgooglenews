defmodule GoogleNews.FetchError do
  @type t :: %__MODULE__{message: String.t(), value: any}

  defexception message: nil, value: nil

  def message(%{message: nil, value: value}) do
    "Could not fetch the resource: #{inspect(value)}"
  end

  def message(%{message: message}) do
    message
  end
end

defmodule GoogleNews.Fetch do
  alias GoogleNews.{Error, FetchError}

  @base_url "https://news.google.com/rss"

  @typedoc """
  Proxy configuration for Mint package.
  """
  @type proxy_descriptor :: {atom, String.t(), integer, list}

  # Get http client (Req) or mock when testing
  defp http_client do
    Application.get_env(:google_news, :http_client, Req)
  end

  # Check response for RSS Feed.
  defp check_response({:ok, %{status: 200, body: body}}), do: body
  defp check_response({:ok, response}), do: raise(FetchError, value: response)
  defp check_response({:error, error}), do: raise(FetchError, value: error)
  defp check_response(unknown), do: raise(Error, message: "Invalid return", value: unknown)

  @doc """
  Retrieve RSS Feed using provided methods.
  """
  @spec fetch!(binary, proxy_descriptor, binary) :: String.t()
  def fetch!(_, proxy, scraping_bee)
      when not is_nil(proxy) and not is_nil(scraping_bee) do
    raise(ArgumentError, message: "Pick either a proxy or ScrapingBee. Not both!")
  end

  def fetch!(url, nil, nil) do
    args = [@base_url <> url, []]

    http_client()
    |> apply(:get, args)
    |> check_response()
  end

  def fetch!(url, proxy, nil)
      when not is_nil(proxy) do
    args = [@base_url <> url, [connect_options: [proxy: proxy]]]

    http_client()
    |> apply(:get, args)
    |> check_response()
  end

  def fetch!(url, nil, scraping_bee)
      when not is_nil(scraping_bee) do
    args = [
      "https://app.scrapingbee.com/api/v1/",
      [
        json: %{
          url: @base_url <> url,
          api_key: scraping_bee,
          render_js: "false"
        }
      ]
    ]

    http_client()
    |> apply(:post, args)
    |> check_response()
  end
end
