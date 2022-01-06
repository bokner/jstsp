defmodule JSTSP do
  @moduledoc """
  Module for solving JSTSP instances.
  """
  import JSTSP.Utils
  require Logger

  def run(instance, opts \\ [])

  def run(instance_file, opts) when is_binary(instance_file) do
    instance_file
    |> get_instance_data()
    |> run_model(opts)
    |> Map.put(:instance, instance_file)
  end

  @doc """
  Run the model on a problem instance
  """
  def run_model(instance, opts \\ [])

  def run_model(instance_data, opts) do
    solver_opts = build_solver_opts(opts)

    {:ok, res} =
      solver_opts
      |> build_model(instance_data)
      |> MinizincSolver.solve_sync(instance_data, solver_opts)

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
    |> then(fn res ->
      is_map(instance_data) && Map.merge(res, instance_data)
      || res end)
  end

  defp build_model(opts, instance_data) do
    opts
    |> build_solver_opts()
    |> add_warm_start()
    |> add_constraints(:upper_bound, instance_data, opts)
    |> add_constraints(:lower_bound, instance_data, opts)
    |> adjust_model_paths()
  end


  defp add_warm_start(opts) do
    case Keyword.get(opts, :warm_start) do
      nil -> opts[:model]
      warm_start_map ->
        [warm_start_model(warm_start_map) | core_model()]
    end
  end

  defp add_constraints(model, :upper_bound, _instance_data, opts) do
    case Keyword.get(opts, :upper_bound) do
      nil -> model
      upper_bound when is_integer(upper_bound) ->
        [inline_model(upper_bound_constraint(upper_bound)) | model]
    end
  end

  defp add_constraints(model, :lower_bound, instance_data, opts) do
    lb_constraint = case Keyword.get(opts, :lower_bound) do
      lower_bound when is_integer(lower_bound) ->
        lower_bound_constraint(lower_bound)
      lower_bound_fun when is_function(lower_bound_fun) ->
        Logger.debug("JOB TOOLS (add_constraints): #{inspect instance_data.job_tools}")
        lower_bound_fun.(instance_data, opts)
      _lower_bound -> nil
    end
    [inline_model(lb_constraint) | model]
  end

  defp adjust_model_paths(model_list) when is_list(model_list) do
    Enum.map(model_list,
    fn {:model_text, _} = model_item -> model_item
      model_file -> Path.join(mzn_dir(), model_file)
    end)
  end

  defp adjust_model_paths(model) do
    adjust_model_paths([model])
  end

  defp warm_start_model(warm_start_map) do
    warm_start_annotations =
      warm_start_map
      |> Enum.map(fn {var, val} -> "warm_start( #{var}, #{MinizincData.elixir_to_dzn(val)})" end)
      |> Enum.join(",\n")

    inline_model(
      """
      solve
        ::
      #{warm_start_annotations}
      minimize cost;
      """)
  end

  def job_cover(instance, opts \\ [])

  def job_cover(instance, opts) when is_binary(instance) do
    instance
    |> get_instance_data()
    |> job_cover(opts)
  end

  def job_cover(instance_data, opts) when is_map(instance_data) do
    solver_opts = build_solver_opts(opts)
    model =
      solver_opts
      |> Keyword.get(:set_cover_model)
      |> adjust_model_paths()
    {:ok, res} = MinizincSolver.solve_sync(model, instance_data, solver_opts)

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

  def get_lower_bound(instance_data, opts \\ [])

  def get_lower_bound(instance_data, opts) when is_map(instance_data) do
    solver_opts = build_solver_opts(opts)
    Logger.debug("JOB TOOLS (get_lower_bound): #{inspect instance_data.job_tools}")
    instance_data
      |> job_cover(solver_opts)
      |> run_on_cover(solver_opts)
      |> then(fn res ->
        lower_bound =
        Map.get(res, :status) == :optimal && Map.get(res, :objective) || 0
        %{lower_bound: lower_bound,
          partial_schedule: get_partial_schedule(Map.get(res, :schedule), instance_data)
        }
      end)
  end

  defp get_partial_schedule(set_cover_schedule, res) do
    Logger.debug("In partial schedule: #{inspect res}")
    set_cover_schedule
  end
  def get_trivial_lower_bound(_instance_data = %{T: tool_num, C: magazine_capacity}) do
    tool_num - magazine_capacity
  end

  defp run_on_cover(cover_results = %{cover: nil}, _opts) do
    cover_results
  end

  defp run_on_cover(cover_results = %{job_tools: job_tools, cover: cover}, opts) do
      job_tools
      |> Enum.zip(cover)
      |> Enum.flat_map(fn {job, cover_flag} -> cover_flag == 1 && [job] || [] end)
      |> then(fn reduced_jobs ->
        cover_results
        |> Map.take([:C, :T])
        |> Map.put(:job_tools, reduced_jobs)
        |> Map.put(:J, length(reduced_jobs))
      end)
      |> run_model(opts)
  end

  def registered_model_opts() do
    [
      upper_bound: &upper_bound_constraint/1,
      lower_bound: &lower_bound_constraint/1,
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
