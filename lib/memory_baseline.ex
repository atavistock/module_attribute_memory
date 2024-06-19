defmodule ModuleBaseline do
  @map Enum.into(1..1_000_000, %{}, fn n -> {"#{n}", n} end)
  def map, do: @map
end

IO.puts :erlang.memory(:total)
