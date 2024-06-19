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

## Tests

All tests are done on a 2023 Apple Macbook M2 Pro with 16GB of ram

### Compiling

Compiled three times deleting the generated `beam` file between each run

Under elixir 1.16.3-otp-26

| cli | time | beam file size |
| --- | --- | --- |
| `/usr/bin/time elixirc memory_baseline.exs` | 13.51 s | 5.65 Mb |
| `/usr/bin/time elixirc memory_baseline.exs` | 11.26 s | 5.65 Mb |
| `/usr/bin/time elixirc memory_baseline.exs` | 13.11 s | 5.65 Mb |
| `/usr/bin/time elixirc memory_bloat.exs` | 40.39 s | 17.19 Mb |
| `/usr/bin/time elixirc memory_bloat.exs` | 46.20 s | 17.19 Mb |
| `/usr/bin/time elixirc memory_bloat.exs` | 42.51 s | 17.19 Mb |

### Inspecting the BEAM file

Disassembling the resulting `beam` file shows very clearly that at least at this phase the map is entire duplicated and inlined directly into each function.

For example:

```
  //Function  Elixir.ModuleBloat:get/1
  label10:  func_info            Elixir.ModuleBloat get 1 //line lib/memory_bloat.ex, 5
  label11:  move                 X[0] X[1]
            move                %{ ..., 100004 => a1, 100005 => a1, ... }
            call_ext_only        2 Elixir.Map:get/2

  //Function  Elixir.ModuleBloat:has_key?/1
  label12:  func_info            Elixir.ModuleBloat has_key? 1 //line lib/memory_bloat.ex, 6
  label13:  bif2                 label00 2 X[0] %{ ..., 100004 => a1, 100005 => a1, ... }
            return

```

### Runtime size

Under elixir 1.16.3-otp-26

| cli | time | peak memory |
| --- | --- | -- |
| `/usr/bin/time -l elixir bin/memory_baseline.exs` | 0.60 s | 275M |
| `/usr/bin/time -l elixir bin/memory_baseline.exs` | 0.60 s | 274M |
| `/usr/bin/time -l elixir bin/memory_baseline.exs` | 0.63 s | 274M |
| `/usr/bin/time -l elixir bin/memory_bloat.exs` | 0.60 s | 271M |
| `/usr/bin/time -l elixir bin/memory_bloat.exs` | 0.63 s | 287M |
| `/usr/bin/time -l elixir bin/memory_bloat.exs` | 0.64 s | 287M |

## Conclusion

