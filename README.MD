# Module Attributes in Elixir

## Whats this about?

Elixir does not have true constants like many other languages. It does have [Module Attributes](https://hexdocs.pm/elixir/module-attributes.html) which can sometimes *feel* like constants.

Module Attributes let a developer reuse the same value or do compile time calculations.  But it does this by evaluating and inlining the value *at compile time*.

## Why did I even ask this question?

I have a project which uses a large `Map` of static values (1m+ key-value pairs, about 25MB of memory) which is loaded from a file at application start, it is accessed frequently, but **never** changes (no adds, deletes, or modifications).

The first implementation I made using a GenServer - theres a single process containing the data as its state and requests load the state and check for a key. This works fine but I was thinking the data is static, so its not really state information so probably doesn't really need a GenServer.

I pondered if the data just be loaded into a module attribute instead?

If its inlined won't there be multiple functions accessing this same data, what will happen if I have `Map.get(@map, key)` and `Map.has_key?(@map, key)`, does the memory footprint double?  What happens if I have 4-5 such methods?

I know that Erlang's virtual machine `BEAM` does a lot to leverage immutability. Values that are the same will literally occupy the same memory space, making the VM incredibly resource efficient.

But really how effective is this? Best way to find out is to test it...

## Tests

All tests are done on a 2023 Apple Macbook M2 Pro with 16GB of ram, using Elixir 1.16.3-otp-26

### Compiling

Compiled three times deleting the generated `.beam` file between each run

| cli | time | beam file size |
| --- | --- | --- |
| `/usr/bin/time elixirc lib/modattr_baseline.ex` | 13.51 s | 5.65 Mb |
| `/usr/bin/time elixirc lib/modattr_baseline.ex` | 11.26 s | 5.65 Mb |
| `/usr/bin/time elixirc lib/modattr_baseline.ex` | 13.11 s | 5.65 Mb |
| `/usr/bin/time elixirc lib/modattr_bloat.ex` | 40.39 s | 17.19 Mb |
| `/usr/bin/time elixirc lib/modattr_bloat.ex` | 46.20 s | 17.19 Mb |
| `/usr/bin/time elixirc lib/modattr_bloat.ex` | 42.51 s | 17.19 Mb |
| `/usr/bin/time elixirc lib/genserver_baseline.ex` | 0.62 s | 5.48k |
| `/usr/bin/time elixirc lib/genserver_baseline.ex` | 0.61 s | 5.48k |
| `/usr/bin/time elixirc lib/genserver_baseline.ex` | 0.61 s | 5.48k |

First its important to note that the GenServer version only populates the map data on init, meaning it is not a realistic comparison at this point. Though as we'll see later the GenServer seems to be able to create the data at run time much, much faster.

At this point it seems that a module attribute is not only inlined, but inlined directly in the bytecode and duplicated for each occurrence.  Disassembling the resulting bytecode in the `.beam` files confirms this.  This explains why the output for the *bloat* version is so many times larger.

Heres a snippet from the *bloat* version where you can see the map occuring multiple times

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

*Each* of those maps literally have 1 million key-value pairs.

### Run-time

To ensure nothing else got pulled in, I deleted and compiled the `.beam` for each type of test, being careful not to leave the older files behind. I ran each type of test 3 times.

| cli | time | peak memory |
| --- | --- | -- |
| `/usr/bin/time -l elixir bin/modattr_baseline.exs` | 0.60 s | 275M |
| `/usr/bin/time -l elixir bin/modattr_baseline.exs` | 0.60 s | 274M |
| `/usr/bin/time -l elixir bin/modattr_baseline.exs` | 0.63 s | 274M |
| `/usr/bin/time -l elixir bin/modattr_bloat.exs` | 0.60 s | 271M |
| `/usr/bin/time -l elixir bin/modattr_bloat.exs` | 0.63 s | 287M |
| `/usr/bin/time -l elixir bin/modattr_bloat.exs` | 0.64 s | 287M |
| `/usr/bin/time -l elixir bin/genserver_baseline.exs` | 1.00 s | 491M |
| `/usr/bin/time -l elixir bin/genserver_baseline.exs` | 0.99 s | 490M |
| `/usr/bin/time -l elixir bin/genserver_baseline.exs` | 1.00 s | 485M |

Super interesting (at least to me).

The more data that is loaded via a module attributes has a significant negative impact on compile times and size of the resulting byte code for `beam`.  But at run-time this completely goes away as the virtual machine seems to share all references to the same data as intended.

Also interesting is the apparent trade off with using static data verses a GenServer.  Compile times and amount of byte code for the GenServer is extremely small, even the run-time latency is within a reasonable tolerance.  But the run-time memory impact of the GenServer seems quite significant.

### More interesting things to look at (at some point in the future)

- These metrics are effectively setting up and then doing only one request for data. I'm curious about how GenServer compares if doing many more requests for data (its not hard to make each go through a loop, I've just not done that yet)

- Erlang has `:persistent_term` which is specifically intended for high read throughput.  It would be interesting to add that to this set of metrics.

- For completeness it might also be fun to add `ets`
