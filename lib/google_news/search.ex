defmodule GoogleNews.Search do
  # Validate date format
  defp date_helper(validate) when is_binary(validate) do
    validate
    |> Date.from_iso8601!()
    |> Date.to_iso8601()
  end

  defp date_helper(validate) do
    raise(ArgumentError,
      message: "cannot parse #{inspect(validate)} as date, reason: :invalid_format"
    )
  end

  @doc """
  Process search query options
  """
  @spec query!(binary, boolean, binary, binary, binary) :: binary
  def query!(text, _, _, _, _) when not is_binary(text),
    do: raise(ArgumentError, message: "Invalid search query")

  def query!(text, helper, when_, _, _) when not is_nil(when_),
    do: query!(text <> " when:" <> when_, helper, nil, nil, nil)

  def query!(text, helper, _, from, to) when not is_nil(from),
    do: query!(text <> " after:" <> date_helper(from), helper, nil, nil, to)

  def query!(text, helper, _, _, to) when not is_nil(to),
    do: query!(text <> " before:" <> date_helper(to), helper, nil, nil, nil)

  def query!(text, helper, _, _, _) when helper, do: URI.encode(text)
  def query!(text, _, _, _, _), do: text
end
