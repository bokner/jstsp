defmodule SSP.Benchmark do
  import SSP.Utils

  def benchmark(instance, opts \\ default_solver_opts())

  def benchmark(instance, opts) when is_binary(instance) do
    instance
    |> get_instance_data()
    |> benchmark(opts)
  end

  def benchmark(instance, opts) when is_map(instance) do
    SSP.run_model(instance, opts)
  end
  def benchmark15x15(opts) do
    benchmark("instances/MTSP/Laporte/Tabela5/L1-2.txt", opts)
  end

  def benchmark25x25(opts) do
    benchmark("instances/MTSP/Laporte/Tabela6/L22-3.txt", opts)
  end

  def benchmark30x40x15(opts) do
    benchmark("instances/MTSP/Catanzaro/C1-1.txt", opts)
  end
end
