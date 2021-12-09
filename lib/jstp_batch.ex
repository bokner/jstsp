defmodule JSTSP.Batch do

  require Logger
  def solvers() do
    ["cplex", "or-tools", "gecode", "yuck", "fzn-oscar-cbls"]
  end

  def run_multiple(instance_files, time_limit) do
    instance_files
    |> Enum.map(fn instance ->
      Logger.info("Instance: #{instance}")
      %{instance: instance, results: run(instance, time_limit)}
    end)
  end
  def run(instance_file, time_limit) do
    Task.async_stream(solvers(),
      fn solver ->
        instance_file
        |> JSTSP.run(solver: solver, time_limit: time_limit)
        |> then(fn {:ok, res} ->
          res
          |> MinizincResults.get_last_solution()
          |> then(fn solution -> %{
            solver: solver,
            objective: MinizincResults.get_solution_objective(solution),
            status: MinizincResults.get_status(res.summary)
          } end)
          end)
      end,
      max_concurrency: length(solvers()), timeout: time_limit * 2
    )
    |> Enum.map(fn {:ok, res} ->
      res
    end)
  end
end
