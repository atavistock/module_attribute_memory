# Memory impacts of Module Attributes in Elixir

## What is it?

I have a project which uses a large `Map` of static values (1m+ key-value pairs, about 25MB of memory) which is loaded from a file at application start, it is read from frequently, but never changes (no adds, deletes, or modifications).

The existing implementation made using a GenServer  Theres a single process containing the data as its state and requests load the state and check the map. This works fine but I was thinking its not really state information.

I pondered if the data just be loaded into a module attribute instead?  If module attributes were actually constants like in other languages that would work fine, but in Elixir they're not true constants and simply inlined at compile time.  Since this is a fairly big amount of data, I started to worry around if there would be duplication of the data, effectively doubling or tripling the memory consumption.  For example would `Map.get(@big_map, key)` and `Map.has_key?(@big_map, key)` be working against different actual maps?

Even deeper down the rabbit hole.  Even if they were different maps, I started to wonder how would data immutability impact the memory footprint; do they effectively become the same reference anyway?  Even if they aren't internally the same reference (because a Map is intrinsically mutable), does the fact that the underlying data always look like {binary, binary} mean that it effectively doesn't matter because 99.9% of the memory is the same references?

So lets test it...

## Compilation

###  Baseline

--- | ---
cli `elixirc lib/memory_baseline.ex`
time `10.69 seconds`
beam file size `7.3 Mb`

###  Bloat

--- | ---
cli `elixirc lib/memory_bloat.ex`
time `46.31 seconds`
beam file size `18.5 Mb`
