defmodule ModuleBaseline do
  @map Enum.into(1..1_000_000, %{}, fn n ->
    str = Integer.to_string(n, 16)
    {str, str}
   end)
  def map, do: @map
end
