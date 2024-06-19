defmodule ModattrBaseline do
  @map Enum.into(1..1_000_000, %{}, fn n ->
    {Integer.to_string(n, 16), Integer.to_string(n, 20) }
   end)

  def keys, do: Map.keys(@map)
end
