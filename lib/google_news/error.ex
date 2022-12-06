defmodule GoogleNews.Error do
  @type t :: %__MODULE__{message: String.t(), value: any}

  defexception message: nil, value: nil

  def message(%{message: nil, value: value}) do
    "GoogleNews found an error: #{inspect(value)}"
  end

  def message(%{message: message}) do
    message
  end
end
