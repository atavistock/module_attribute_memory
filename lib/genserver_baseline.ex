defmodule GenserverBaseline do

  use GenServer

  @impl GenServer
  def init(_opts) do
    map = Enum.into(1..1_000_000, %{}, fn n ->
      {Integer.to_string(n, 16), Integer.to_string(n, 20) }
     end)
    {:ok, map}
  end

  @impl GenServer
  def handle_call(:keys, _from, map) do
    {:reply, Map.keys(map), map}
  end

  def keys do
    GenServer.call(:genserver_baseline, :keys)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :genserver_baseline)
  end
end
