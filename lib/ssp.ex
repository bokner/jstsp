defmodule SSP do
  @moduledoc """
  Module for solving SSP instances.
  """
  import SSP.Utils

  alias SSP.SetCover

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


    solver_result =
      solver_opts
      |> build_model(instance_data)
      |> MinizincSolver.solve_sync(build_data(instance_data), solver_opts)

    case solver_result do
      {:ok, res} ->
        res
          |> MinizincResults.get_last_solution()
          |> then(fn solution ->
            %{
              solver: res.summary.solver,
              time_limit: solver_opts[:time_limit],
              objective: MinizincResults.get_solution_objective(solution),
              status: MinizincResults.get_status(res.summary),
              sequence: MinizincResults.get_solution_value(solution, "sequence"),
              magazine: MinizincResults.get_solution_value(solution, "magazine")
            }
          end)
          |> then(fn res ->
            {:ok,
            is_map(instance_data) && Map.merge(res, instance_data)
            || res} end)
       {:error, error} ->
          {:error, error}
      end
  end

  defp build_model(opts, instance_data) do
    opts
    |> build_solver_opts()
    |> normalize_model()
    |> add_warm_start()
    |> add_constraints(:upper_bound, instance_data, opts)
    |> add_constraints(:lower_bound, instance_data, opts)
    |> add_constraints(:symmetry_breaking, instance_data, opts)
    |> adjust_model_paths(opts[:mzn_dir])
  end

  defp normalize_model(opts) do
    is_list(opts[:model]) && opts
    || Keyword.put(opts, :model, [opts[:model]])
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
      lower_bound_fun when is_function(lower_bound_fun) ->
        lower_bound_fun.(instance_data, opts)
      lower_bound -> lower_bound_constraint(lower_bound)
    end
    [inline_model(lb_constraint) | model]
  end

  defp add_constraints(model, :symmetry_breaking, _instance_data, opts) do
    Keyword.get(opts, :symmetry_breaking, true) && ["symmetry_breaking.mzn" | model]
    || model
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



  def get_lower_bound(instance_data, opts \\ [])

  def get_lower_bound(instance_data, opts) when is_map(instance_data) do
    solver_opts = build_solver_opts(opts)
    instance_data
      |> SetCover.job_cover(solver_opts)
      |> run_on_cover(solver_opts)
      |> then(fn {:ok, res} ->
        lower_bound =
        Map.get(res, :status) == :optimal && Map.get(res, :objective) || 0
        %{lower_bound: lower_bound,
          partial_sequence: get_partial_sequence(res, instance_data),
          total_jobs: instance_data[:J]
        }
        |> tap(fn lb ->
          trivial_lb = get_trivial_lower_bound(instance_data)
          lb.lower_bound > trivial_lb &&
          Logger.warn("Better than trivial lower bound (#{trivial_lb}) found: #{inspect lb.lower_bound}")
         end)
      {:error, error} -> error
        other ->
          Logger.error("Unexpected result for lower bound: #{inspect other}")
          %{lower_bound: 0}
        end
      )
  end

  defp get_partial_sequence(res, instance_data) do
    Enum.map(res.sequence, fn job_num ->
      Enum.find_index(instance_data.job_tools, fn job ->
        job == Enum.at(res.job_tools, job_num - 1)
      end) + 1
    end)
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
      sequence_constraint: &sequence_constraint/1,
      warm_start: &sequence_warm_start/1
    ]
  end

end

defmodule SSP.MinizincHandler do
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
    Logger.debug("Time elapsed: #{summary && summary.time_elapsed}")

    DefaultHandler.handle_summary(summary)
  end

  @doc false
  def handle_minizinc_error(error) do
    Logger.debug("Minizinc error: #{inspect(error)}")
    DefaultHandler.handle_minizinc_error(error)
  end
end
