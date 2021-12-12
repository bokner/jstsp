defmodule JSTSP do
  @moduledoc """
  Module for solving JSTSP instances.
  """
  import JSTSP.Utils

  def run(instance, opts \\ [])

  def run(instance_file, opts) when is_binary(instance_file) do
    instance_file
    |> parse_instance()
    |> run_model(opts)
  end


  @doc """
  Run the model on a problem instance
  """
  def run_model(instance, opts \\ [])

  def run_model(data_instance, solver_opts) do
    solver_opts = Keyword.merge(default_solver_opts(), solver_opts)

    {:ok, res} = MinizincSolver.solve_sync(get_model(solver_opts), data_instance, solver_opts)
    res
    |> MinizincResults.get_last_solution()
    |> then(fn solution -> %{
      solver: res.summary.solver,
      objective: MinizincResults.get_solution_objective(solution),
      status: MinizincResults.get_status(res.summary),
      schedule: MinizincResults.get_solution_value(solution, "schedule")
    } end)
    |> Map.merge(data_instance)
  end

  defp get_model(opts) do
    Path.join([:code.priv_dir(:jstsp), "mzn", Keyword.get(opts, :model)])
  end

  def default_solver_opts do
    [
      solver: "gecode",
      solution_handler: JSTSP.MinizincHandler,
      time_limit: 30_000,
      model: "jstsp.mzn"
    ]
  end
end

defmodule JSTSP.MinizincHandler do
  @moduledoc false

  require Logger
  alias MinizincHandler.Default, as: DefaultHandler
  use MinizincHandler

  @doc false
  def handle_solution(solution = %{index: _count, data: _data}) do
    Logger.info(
      "Objective: #{MinizincResults.get_solution_objective(solution)}"
    )

    DefaultHandler.handle_solution(solution)
  end

  @doc false
  def handle_summary(summary) do
    Logger.info("MZN final status: #{summary[:status]}")
    DefaultHandler.handle_summary(summary)
  end

  @doc false
  def handle_minizinc_error(error) do
    Logger.info("Minizinc error: #{inspect(error)}")
    DefaultHandler.handle_minizinc_error(error)
  end
end
