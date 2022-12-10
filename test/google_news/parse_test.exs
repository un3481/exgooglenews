defmodule GoogleNews.ParseTest do
  use ExUnit.Case, async: true

  alias GoogleNews.{Feed, FeedInfo, Entry}
  alias GoogleNews.Parse
  alias GoogleNews.ParseError

  test "error on parse, reason: :parser_error (invalid rss 1)" do
    error = %ParseError{
      reason: :parser_error,
      value: 'Can\'t detect character encoding due to lack of indata'
    }

    result =
      try do
        Parse.parse!("")
      rescue
        err in [ParseError, ArgumentError] -> err
      end

    assert error == result
  end

  test "error on parse, reason: :parser_error (invalid rss 2)" do
    error = %ParseError{
      reason: :parser_error,
      value: 'Continuation function undefined'
    }

    result =
      try do
        Parse.parse!("<rss bff65")
      rescue
        err in [ParseError, ArgumentError] -> err
      end

    assert error == result
  end

  test "error on parse, reason: :parser_error (invalid rss 3)" do
    error = %ParseError{
      reason: :parser_error,
      value: '\', " or whitespace expected'
    }

    result =
      try do
        Parse.parse!("<rss version=\\\"2.0\\\"></rss>")
      rescue
        err in [ParseError, ArgumentError] -> err
      end

    assert error == result
  end

  test "error on parse, reason: :parser_error (invalid rss 4)" do
    error = %ParseError{
      reason: :parser_error,
      value: 'EndTag: :rss, does not match StartTag'
    }

    result =
      try do
        Parse.parse!("<rss><channel></rss>")
      rescue
        err in ParseError -> err
      end

    assert error == result
  end

  test "ok on parse (parsing empty rss)" do
    result = Parse.parse!("<rss version=\"2.0\"></rss>")

    assert result == %Feed{}
  end

  test "ok on parse (parsing feed not-found)" do
    result =
      "test/documents/not_found.rss"
      |> File.read!()
      |> Parse.parse!()

    assert result.__struct__ == Feed

    %Feed{feed: feed, entries: entries} = result

    assert feed.__struct__ == FeedInfo
    assert feed.title == "Google News"
    assert Enum.count(entries) == 1

    entry = Enum.at(entries, 0)

    assert entry.__struct__ == Entry
    assert entry.title == "This feed is not available."
  end
end
