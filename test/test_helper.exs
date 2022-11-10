ExUnit.start()

defmodule ReqBehaviour do
  @callback get!(String.t() | Req.Request.t(), options :: keyword()) :: Req.Response.t()
  @callback post!(String.t() | Req.Request.t(), options :: keyword()) :: Req.Response.t()
end

Mox.defmock(ReqMock, for: ReqBehaviour)

Application.put_env(:google_news, :http_client, ReqMock)
