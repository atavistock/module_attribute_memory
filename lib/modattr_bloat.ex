defmodule ModattrBloat do
  @map Enum.into(1..1_000_000, %{}, fn n ->
    {Integer.to_string(n, 16), Integer.to_string(n, 20) }
  end)

  def map, do: @map
  def get(key), do: Map.get(@map, key)
  def has_key?(key), do: Map.has_key?(@map, key)
  def keys, do: Map.keys(@map)
end
