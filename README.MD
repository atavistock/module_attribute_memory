# How Module Attributes in Elixir can cause bloat

## What / Why?

Elixir does not have true constants like many other languages. It does have [Module Attributes](https://hexdocs.pm/elixir/module-attributes.html) which can sometimes *feel* like constants.

Module Attributes let a developer reuse the same value or do compile time calculations.  But it does this by evaluating and inlining the value *at compile time*.

## Why did I even ask this question?

I have a project which uses a large `Map` of static values (1m+ key-value pairs, about 25MB of memory) which is loaded from a file at application start, it is read from frequently, but never changes (no adds, deletes, or modifications).

The existing implementation made using a GenServer - theres a single process containing the data as its state and requests load the state and check for a key. This works fine but I was thinking the data is static, so its not really state information.

I pondered if the data just be loaded into a module attribute instead?

If its inlined won't there be multiple functions accessing this same data, what will happen if I have `Map.get(@big_map, key)` and `Map.has_key?(@big_map, key)`, does the memory footprint double?  What happens if I have 4-5 such methods?

Elixir and Erlang's BEAM go to some extra measures to help manage memory by tracking immutable objects as the same reference, would that effective remove any issue caused by multiple reference?are really good at reusing the same references.

Best way to find out is to test it...

## Compilation

| elixir | cli | time | beam file size |
| --- | --- | --- | --- |
| 1.16.3-otp-26 | `elixirc lib/memory_baseline.ex` | 10.69 s | 7.3 Mb |
| 1.13.4-otp-25 | `elixirc lib/memory_baseline.ex` | 8.37 s | 11.7 Mb |
| 1.16.3-otp-26 | `elixirc lib/memory_bloat.ex` | 46.31 s | 18.5 Mb |
| 1.13.4-otp-25 | `elixirc lib/memory_bloat.ex` | 30.12 s | 36.2 Mb |
