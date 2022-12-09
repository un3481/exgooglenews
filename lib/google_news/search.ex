defmodule GoogleNews.Search do
  @moduledoc """

  Helper functions for building Google News search queries

  """

  # validate when parameter
  defp is_when(value) do
    unless is_binary(value) do
      raise(ArgumentError,
        message: "invalid option, ':when' is not a string: #{inspect(value)}"
      )
    end

    value
  end

  # Validate date parameter
  defp is_date(value) when is_binary(value) do
    value
    |> Date.from_iso8601!()
    |> Date.to_iso8601()
  end

  defp is_date(value) do
    raise(ArgumentError,
      message: "cannot parse #{inspect(value)} as date, reason: :invalid_format"
    )
  end

  # Reduce query from options
  defp reduce(text, w, _, _) when not is_nil(w),
    do: reduce("#{text} when:#{is_when(w)}", nil, nil, nil)

  defp reduce(text, _, from, to) when not is_nil(from),
    do: reduce("#{text} after:#{is_date(from)}", nil, nil, to)

  defp reduce(text, _, _, to) when not is_nil(to),
    do: reduce("#{text} before:#{is_date(to)}", nil, nil, nil)

  defp reduce(text, _, _, _), do: text

  @doc """
  Process search query options

  ## Search Options

    * `:when` - sets the time range for the published datetime.

    * `:from` - sets the minimum date for articles that can be found.

    * `:to` - sets the maximum date for articles that can be found.

  The `:when` option works as following: `m` for month, `d` for days and `h` for hours.
  If option `when: "12h"` is given, it will search for only the articles matching the `search` criteria and published for the last 12 hours.
  Options `:from` and `:to` accept the following format of date: `%Y-%m-%d`. For example, `2020-07-01`.

  ## Examples

  Build search query for articles about `boeing` published since November 19th, 2022

      iex> GoogleNews.Search.query!("boeing", from: "2022-11-19")
      "boeing after:2022-11-23"

  Build search query for articles that contain `boeing` in title published in the last 3 days

      iex> GoogleNews.Search.query!("intitle:boeing", when: "3d")
      "intitle:boeing when:3d"

  """
  @spec query!(binary, list) :: binary
  def query!(query, opts \\ []) when is_binary(query) and is_list(opts) do
    reduce(query, opts[:when], opts[:from], opts[:to])
  end
end
