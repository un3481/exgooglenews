defmodule GooglenewsTest do
  use ExUnit.Case
  doctest Googlenews

  test "ok on 200" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{
        status: 200,
        body: File.read!("test/documents/sample.xml")
      }
    end)

    {:ok, %{feed: feed, entries: entries}} = Googlenews.top_news()

    assert feed.__struct__ == FeederEx.Feed

    entries
    |> Enum.each(fn entry ->
      assert entry.__struct__ == FeederEx.Entry
    end)
  end

  test "error on 404" do
    Mox.expect(ReqMock, :get!, fn _, _ ->
      %Req.Response{status: 404}
    end)

    assert {:error, "status_code: 404 body: \"\""} == Googlenews.top_news()
  end
end
