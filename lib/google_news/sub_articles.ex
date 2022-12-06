defmodule GoogleNews.SubArticles do
  # Return subarticles from the main and topic feeds.
  defp parser(text) when is_binary(text) do
    text
    |> Floki.parse_document!()
    |> Floki.find("li")
    |> Enum.map(fn li ->
      a = Floki.find(li, "a")
      font = Floki.find(li, "font")

      %{
        title: Floki.text(a),
        url: Floki.attribute(a, "href"),
        publisher: Floki.text(font)
      }
    end)
  end

  @doc """
  Merge Sub Articles to entries
  """
  @spec merge!(list) :: list
  def merge!(entries) when is_list(entries) do
    entries
    |> Enum.map(fn entry ->
      Map.merge(
        entry,
        %{
          sub_articles:
            if Map.get(entry, :summary) != nil do
              parser(Map.get(entry, :summary))
            else
              nil
            end
        }
      )
    end)
  end
end
