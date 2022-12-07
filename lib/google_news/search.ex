defmodule GoogleNews.Search do
  # Validate date format
  defp check_date(validate) when is_binary(validate) do
    validate
    |> Date.from_iso8601!()
    |> Date.to_iso8601()
  end

  defp check_date(validate) do
    raise(ArgumentError,
      message: "cannot parse #{inspect(validate)} as date, reason: :invalid_format"
    )
  end

  # Reduce query from options
  defp reduce(text, w, _, _) when not is_nil(w),
    do: reduce("#{text} when:#{w}", nil, nil, nil)

  defp reduce(text, _, from, to) when not is_nil(from),
    do: reduce("#{text} after:#{check_date(from)}", nil, nil, to)

  defp reduce(text, _, _, to) when not is_nil(to),
    do: reduce("#{text} before:#{check_date(to)}", nil, nil, nil)

  defp reduce(text, _, _, _), do: text

  @doc """
  Process search query options
  """
  @spec query!(binary, list) :: binary
  def query!(query, opts \\ []) when is_binary(query) and is_list(opts) do
    reduce(query, opts[:when], opts[:from], opts[:to])
  end
end
