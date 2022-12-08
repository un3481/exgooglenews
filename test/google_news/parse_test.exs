defmodule GoogleNews.ParseTest do
  use ExUnit.Case, async: true

  test "error on parse, reason: :parser_error (invalid rss 1)" do
    error = %GoogleNews.ParseError{
      reason: :parser_error,
      value: 'Can\'t detect character encoding due to lack of indata'
    }

    result =
      try do
        GoogleNews.Parse.parse!("")
      rescue
        err -> err
      end

    assert error == result
  end

  test "error on parse, reason: :parser_error (invalid rss 2)" do
    error = %GoogleNews.ParseError{
      reason: :parser_error,
      value: 'Continuation function undefined'
    }

    result =
      try do
        GoogleNews.Parse.parse!("<rss bff65")
      rescue
        err -> err
      end

    assert error == result
  end

  test "error on parse, reason: :parser_error (invalid rss 3)" do
    error = %GoogleNews.ParseError{
      reason: :parser_error,
      value: '\', " or whitespace expected'
    }

    result =
      try do
        GoogleNews.Parse.parse!("<rss version=\\\"2.0\\\"></rss>")
      rescue
        err -> err
      end

    assert error == result
  end

  test "error on parse, reason: :parser_error (invalid rss 4)" do
    error = %GoogleNews.ParseError{
      reason: :parser_error,
      value: 'EndTag: :rss, does not match StartTag'
    }

    result =
      try do
        GoogleNews.Parse.parse!("<rss><channel></rss>")
      rescue
        err -> err
      end

    assert error == result
  end

  test "ok on parse (parsing empty rss)" do
    feed = %GoogleNews.Feed{}

    result =
      try do
        GoogleNews.Parse.parse!("<rss version=\"2.0\"></rss>")
      rescue
        err -> err
      end

    assert feed == result
  end
end
