defmodule GoogleNews.FetchError do
  @type t :: %__MODULE__{reason: atom, value: any}

  defexception reason: nil, value: nil

  def message(%{reason: reason, value: value}) do
    case reason do
      :response_status -> "invalid response status code: #{inspect(value.status)}"
      :request_error -> "error on http client: #{inspect(value)}"
      :invalid_output -> "invalid output from http client: #{inspect(value)}"
      _ -> "could not fetch the resource: #{inspect(value)}"
    end
  end
end

defmodule GoogleNews.Fetch do
  alias GoogleNews.FetchError

  @typedoc """
  Proxy configuration for Mint package.
  """
  @type proxy_descriptor :: {atom, String.t(), integer, list}

  # Encode URL and check consistency.
  defp encode(text, opts) do
    text =
      if Keyword.get(opts, :encode, true),
        do: URI.encode(text),
        else: text

    uri = URI.parse(text)

    unless uri.host in [nil, "news.google.com"] do
      raise(ArgumentError, message: "invalid uri host: #{inspect(uri.host)}")
    end

    %URI{
      path: uri.path,
      query: uri.query,
      port: uri.port || 443,
      scheme: uri.scheme || "https"
    }
  end

  # Merge base uri to input path.
  defp merge_base(uri) do
    sep_sw = ["/"]
    sep_eq = [nil, ""] ++ sep_sw
    pfx_sw = ["rss/", "/rss/"]
    pfx_eq = ["rss", "/rss"] ++ pfx_sw

    sep_ok = uri.path in sep_eq or String.starts_with?(uri.path || "", sep_sw)
    pfx_ok = uri.path in pfx_eq or String.starts_with?(uri.path || "", pfx_sw)

    sep = if sep_ok, do: "", else: "/"
    pfx = if pfx_ok, do: "", else: "/rss"

    uri
    |> Map.put(:path, "#{pfx}#{sep}#{uri.path}")
    |> Map.put(:authority, "news.google.com")
    |> Map.put(:host, "news.google.com")
  end

  # Compile correct country-lang parameters for Google News RSS URL.
  defp add_ceid(uri, opts) do
    lang = Keyword.get(opts, :lang, "en")
    country = Keyword.get(opts, :country, "US")

    ceid = [
      {"ceid", "#{country}:#{lang}"},
      {"hl", lang},
      {"gl", country}
    ]

    query =
      (uri.query || "")
      |> URI.query_decoder()
      |> Enum.to_list()
      |> Kernel.++(ceid)
      |> URI.encode_query()

    uri
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  # Get http client (Req) or mock when testing
  defp http_client do
    Application.get_env(:google_news, :http_client, Req)
  end

  # Send request to uri using proxy or scraping bee.
  defp request(uri, nil, nil) do
    args = [uri, []]

    http_client() |> apply(:get, args)
  end

  defp request(_, proxy, scraping_bee) when not is_nil(proxy) and not is_nil(scraping_bee) do
    raise(ArgumentError, message: "use either :proxy or :scraping_bee, not both")
  end

  defp request(uri, proxy, nil) when not is_nil(proxy) do
    args = [uri, [connect_options: [proxy: proxy]]]

    http_client() |> apply(:get, args)
  end

  defp request(uri, nil, scraping_bee) when not is_nil(scraping_bee) do
    args = [
      "https://app.scrapingbee.com/api/v1/",
      [
        json: %{
          url: uri,
          api_key: scraping_bee,
          render_js: "false"
        }
      ]
    ]

    http_client() |> apply(:post, args)
  end

  # Handle response for RSS Feed.
  defp handle_response({:ok, %{status: 200, body: body}}), do: body

  defp handle_response({:ok, response}) do
    raise(FetchError, reason: :response_status, value: response)
  end

  defp handle_response({:error, error}) do
    raise(FetchError, reason: :request_error, value: error)
  end

  defp handle_response(value) do
    raise(FetchError, reason: :invalid_output, value: value)
  end

  @doc """
  Retrieve RSS Feed using provided methods.

  @param boolean encode: When True helps with URL quoting.
  """
  @spec fetch!(binary, list) :: binary
  def fetch!(uri, opts \\ []) when is_binary(uri) and is_list(opts) do
    uri
    |> encode(opts)
    |> merge_base()
    |> add_ceid(opts)
    |> request(opts[:proxy], opts[:scraping_bee])
    |> handle_response()
  end
end
