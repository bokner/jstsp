defmodule JSTSP.Batch do
  require Logger

  def solvers() do
    ["cplex", "or-tools", "gecode", "yuck", "fzn-oscar-cbls"]
  end

  def run_multiple(instance_files, time_limit, solvers \\ solvers()) do
    instance_num = length(instance_files)

    instance_files
    |> Enum.with_index(1)
    |> Enum.map(fn {instance, idx} ->
      Logger.info("Instance: #{instance} (#{idx} of #{instance_num})")
      %{instance: instance, results: run(instance, time_limit, solvers)}
    end)
  end

  def run(instance_file, time_limit, solvers \\ solvers())

  def run(instance_file, time_limit, solvers) do
    Task.async_stream(
      solvers,
      fn solver ->
        instance_file
        |> JSTSP.run(solver: solver, time_limit: time_limit)
      end,
      max_concurrency: length(solvers()),
      timeout: time_limit * 2
    )
    |> Enum.map(fn {:ok, res} ->
      res
    end)
  end
end
