defmodule ModuleBaseline do
  @map Enum.into(1..1_000_000, %{}, fn n -> {
    Integer.to_string(n, 36), "a#{n}"
  } end)
  def map, do: @map
end
