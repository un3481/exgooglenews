defmodule GooglenewsTest do
  use ExUnit.Case
  doctest Googlenews

  test "checks return type" do
    assert %{feed: _, entries: _} == Googlenews.top_news()
  end
end
