defmodule JSTSP do
  @moduledoc """
  Module for solving JSTSP instances.
  """
  import JSTSP.Utils
  require Logger

  def run(instance, opts \\ [])

  def run(instance_file, opts) when is_binary(instance_file) do
    opts = Keyword.merge(default_solver_opts(), opts)
    instance_file
    |> instance_data()
    |> run_model(opts)
    |> Map.put(:instance, instance_file)
  end

  @doc """
  Run the model on a problem instance
  """
  def run_model(instance, opts \\ [])

  def run_model(instance_data, solver_opts) do
    solver_opts = Keyword.merge(default_solver_opts(), solver_opts)

    {:ok, res} = MinizincSolver.solve_sync(get_model(solver_opts), instance_data, solver_opts)

    res
    |> MinizincResults.get_last_solution()
    |> then(fn solution ->
      %{
        solver: res.summary.solver,
        time_limit: solver_opts[:time_limit],
        objective: MinizincResults.get_solution_objective(solution),
        status: MinizincResults.get_status(res.summary),
        schedule: MinizincResults.get_solution_value(solution, "schedule"),
        magazine: MinizincResults.get_solution_value(solution, "magazine")
      }
    end)
    |> Map.merge(instance_data)
  end

  defp get_model(opts, model_type \\ :model)

  defp get_model(opts, model_type) do
    instance_model =
      case Keyword.get(opts, model_type) do
        model when is_list(model) -> build_model(model)
        model -> build_model([model])
      end

    registered_constraints()
    |> Enum.reduce(instance_model, fn {constraint, fun}, acc ->
      case Keyword.get(opts, constraint) do
        nil -> acc
        arg -> [{:model_text, fun.(arg)} | acc]
      end
    end)
  end

  defp build_model(model_list) do
    Enum.map(model_list, fn
      {:model_text, model} -> {:model_text, model}
      model_file -> Path.join([mzn_dir(), model_file])
    end)
  end

  def job_cover(instance, opts \\ [])

  def job_cover(instance, opts) when is_binary(instance) do
    instance
    |> instance_data()
    |> job_cover(opts)
  end

  def job_cover(instance_data, solver_opts) when is_map(instance_data) do
    solver_opts = Keyword.merge(default_solver_opts(), solver_opts)
    Logger.debug("Solver opts: #{inspect solver_opts}")
    {:ok, res} = MinizincSolver.solve_sync(get_model(solver_opts, :set_cover_model), instance_data, solver_opts)

    res
    |> MinizincResults.get_last_solution()
    |> then(fn solution ->
      %{
        solver: res.summary.solver,
        time_limit: solver_opts[:time_limit],
        objective: MinizincResults.get_solution_objective(solution),
        status: MinizincResults.get_status(res.summary),
        cover: MinizincResults.get_solution_value(solution, "cover")
      }
    end)
    |> Map.merge(instance_data)
  end

  def registered_constraints() do
    [
      upper_bound: &upper_bound_constraint/1,
      schedule_constraint: &schedule_constraint/1,
      warm_start: &schedule_warm_start/1
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
    Logger.info("Objective: #{MinizincResults.get_solution_objective(solution)}")

    DefaultHandler.handle_solution(solution)
  end

  @doc false
  def handle_summary(summary) do
    last_solution = MinizincResults.get_last_solution(summary)

    Logger.debug(
      "MZN final status (#{summary.solver}): #{summary.status}, objective: #{MinizincResults.get_solution_objective(last_solution)}"
    )

    DefaultHandler.handle_summary(summary)
  end

  @doc false
  def handle_minizinc_error(error) do
    Logger.debug("Minizinc error: #{inspect(error)}")
    DefaultHandler.handle_minizinc_error(error)
  end
end
