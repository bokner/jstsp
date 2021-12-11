# JSTSP

**Framework for solving/benchmarking Job sequencing And Tool Switching Problem**

Usage:
```elixir
instance_file_d4_1 = "instances/MTSP/Catanzaro/D4-1.txt"
JSTSP.Batch.run(instance_file_d4_1, 300000)  
## or
JSTSP.run(instance_file_d4_1, solver: "gecode", time_limit: 300000)  
```




## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jstsp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jstsp, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/jstsp](https://hexdocs.pm/jstsp).

