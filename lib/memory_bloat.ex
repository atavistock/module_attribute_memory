
defmodule ModuleBloat do
  @map Enum.into(1..1_000_000, %{}, fn n -> {"#{n}", n} end)
  def map, do: @map
  def get(key), do: Map.get(@map, key)
  def has_key?(key), do: Map.has_key?(@map, key)
  def keys, do: Map.keys(@map)
end

IO.puts :erlang.memory(:total)
