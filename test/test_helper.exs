ExUnit.start()

defmodule ReqBehaviour do
  @doc "Callback for Req.get/2"
  @callback get(Req.url() | Req.Request.t(), options :: keyword()) ::
              {:ok, Req.Response.t()} | {:error, Exception.t()}

  @doc "Callback for Req.post/2"
  @callback post(Req.url() | Req.Request.t(), options :: keyword()) ::
              {:ok, Req.Response.t()} | {:error, Exception.t()}
end

Mox.defmock(ReqMock, for: ReqBehaviour)

Application.put_env(:google_news, :http_client, ReqMock)
