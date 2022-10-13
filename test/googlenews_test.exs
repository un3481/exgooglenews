defmodule GooglenewsTest do
  use ExUnit.Case
  doctest Googlenews

  test "check return type" do
    %{feed: _, entries: entries} = Googlenews.top_news!()

    entries
    |> Enum.each(fn entry ->
      assert FeederEx.Entry == entry.__struct__
    end)
  end
end
