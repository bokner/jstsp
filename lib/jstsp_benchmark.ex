defmodule JSTSP.Benchmark do
  import JSTSP.Utils
  def benchmark15x15(opts \\ default_solver_opts()) do
    instance = "instances/MTSP/Laporte/Tabela5/L1-2.txt"
    instance
    |> get_instance_data()
    |> JSTSP.run_model(opts)
  end
end
