defmodule JSTSP do
  @moduledoc """
  Module for solving JSTSP instances.
  """
  import JSTSP.Utils

  def run(instance, opts \\ [])

  def run(instance_file, opts) when is_binary(instance_file) do
    instance_file
    |> instance_data()
    |> run_model(opts)
    |> Map.put(:instance, instance_file)
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
    |> Map.merge(data_instance)
  end

  defp get_model(opts) do
    instance_model =
      case Keyword.get(opts, :model) do
        model when is_list(model) -> build_model(model)
        model -> build_model([model])
      end

    case Keyword.get(opts, :upper_bound) do
      nil ->
        instance_model

      upper_bound ->
        [{:model_text, upper_bound_constraint(upper_bound)} | instance_model]
    end
  end

  defp build_model(model_list) do
    Enum.map(model_list, fn
      {:model_text, model} -> {:model_text, model}
      model_file -> Path.join([:code.priv_dir(:jstsp), "mzn", model_file])
    end)
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
