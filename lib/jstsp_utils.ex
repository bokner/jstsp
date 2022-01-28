defmodule JSTSP.Utils do
  require Logger

  def default_solver_opts do
    [
      solver: "cplex",
      solution_handler: JSTSP.MinizincHandler,
      time_limit: 300_000,
      model: standard_model(),
      mzn_dir: mzn_dir(),
      symmetry_breaking: true
    ]
  end

  def default_set_cover_opts do
    [
      solver: "cplex",
      solution_handler: JSTSP.MinizincHandler,
      time_limit: 300_000,
      mzn_dir: mzn_dir(),
      model: "setcover.mzn"
    ] |> build_extra_flags()
  end

  ## Build solver opts from model opts
  def build_solver_opts(model_opts) do
    Keyword.merge(default_solver_opts(), model_opts)
    |> build_extra_flags()
  end

  defp build_extra_flags(opts) do
    Enum.map([:mzn_dir, :symmetry_breaking, :extra_flags],
      fn flag -> build_flag(flag, opts) end)
    |> Enum.join(" ")
    |> then(fn flags -> Keyword.put(opts, :extra_flags, flags) end)
  end

  defp build_flag(:mzn_dir, opts) do
    mzn_dir = Keyword.get(opts, :mzn_dir)
    mzn_dir && mzn_dir_flag(mzn_dir)
  end

  defp build_flag(:symmetry_breaking, _opts) do
    #ignore_symmetry_flag(!bool)
    nil
  end

  defp build_flag(:extra_flags, opts) do
    Keyword.get(opts, :extra_flags) || ""
  end

  def standard_model() do
    ["solve_definition.mzn" | core_model()]
  end

  def core_model() do
    [
      "jstsp_pars.mzn",
      "jstsp_vars.mzn",
    "jstsp_constraints.mzn",
    "predicates_functions.mzn"]
  end

  def mzn_dir() do
    Path.join(:code.priv_dir(:jstsp), "mzn")
  end

  def mzn_dir_experimental() do
    Path.join(:code.priv_dir(:jstsp), "mzn-experimental")
  end

  def get_instance_data(file) do
    Path.extname(file) == ".dzn" && file ||
    file
    |> parse_instance_file()
    |> Map.put(:instance, file)

  end

  defp parse_instance_file(instance_file) do
    parsed_data =
      instance_file
      |> File.read!()
      |> String.split("\r\n", trim: true)
      |> Enum.flat_map(fn line ->
        line
        |> String.split([" ", "\t"], trim: true)
        |> Enum.map(fn numstr ->
          numstr
          |> String.trim()
          |> String.to_integer()
        end)
      end)

    [j, t, c | job_tools] = parsed_data

    job_tool_matrix =
      job_tools
      |> Enum.chunk_every(j)
      |> transpose()

    # Check if the JT matrix matches the sizes claimed by the instance
    true = j == length(job_tool_matrix) && t == length(hd(job_tool_matrix))

    %{
      T: t,
      J: j,
      C: c,
      job_tools: job_tool_matrix
    }

  end

  def transpose(matrix) do
    matrix
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  def to_csv(results, filename) do
    header = "instance,J,T,C,solver,time_limit(msec),status,objective,schedule"

    :ok =
      results
      |> Enum.reduce(
        [header],
        fn
          %{instance: instance, results: solver_results}, acc ->
            acc ++
              Enum.map(
                solver_results,
                fn res -> result_to_csv(instance, res) end
              )

          %{instance: instance} = res, acc ->
            acc ++ [result_to_csv(instance, res)]
        end
      )
      |> Enum.join("\n")
      |> then(fn content -> File.write(filename, content) end)
  end

  def csv_to_cubdb(csv_file) do
    csv_file
    |> JSTSP.Results.parse_results()
    |> Enum.each(fn rec -> to_cubdb(rec) end)
  end

  def to_cubdb(instance_rec) do
    CubDB.put(:cubdb, {:instance, instance_rec.instance}, instance_rec)
  end
  def result_to_csv(
        instance,
        _result = %{
          T: tools,
          J: jobs,
          C: capacity,
          solver: solver,
          time_limit: time_limit,
          status: status,
          objective: objective,
          schedule: schedule
        }
      ) do
    schedule_str = is_list(schedule) && "#{inspect schedule}" || schedule
    "#{instance},#{jobs},#{tools},#{capacity},#{solver},#{time_limit},#{status},#{objective},\"#{schedule_str}\""
  end

  def non_optimal_results(csv_file) do
    csv_file
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Enum.map(fn {:ok, rec} -> rec end)
    |> Enum.reject(fn rec -> rec["status"] == "optimal" end)
  end

  def upper_bound_constraint(upper_bound) when is_integer(upper_bound) do
    "constraint cost <= #{upper_bound};"
  end

  def lower_bound_constraint(lower_bound) when is_integer(lower_bound) do
    "constraint cost >= #{lower_bound};"
  end

  def lower_bound_constraint(lower_bound_map = %{partial_schedule: partial_schedule, total_jobs: total_jobs}) do
    schedule_str =
      Enum.join(
        lower_bound_map.partial_schedule ++
        List.duplicate("_", total_jobs - length(partial_schedule)), ", ")
    lower_bound_constraint(lower_bound_map.lower_bound) <> "\n" <>
    "schedule = [#{schedule_str}];\n"
  end

  def lower_bound_constraint(_lower_bound) do
    ""
  end

  def schedule_constraint(schedule) do
    "constraint schedule = #{inspect(schedule)};"
  end

  def normalize_schedule(schedule) do
    List.first(schedule) < List.last(schedule) && schedule
    || Enum.reverse(schedule)
  end
  def schedule_warm_start(schedule) do
    """
    annotation warm_start(schedule,
      #{MinizincData.elixir_to_dzn(schedule)}
    );
    """
  end

  def count_switches(schedule, magazine) do
    magazine_sequence =
      Enum.map(
        0..(length(schedule) - 1),
        fn i ->
          magazine
          |> Enum.at(i)
          #|> Enum.at(Enum.at(schedule, i) - 1)
          |> to_toolset()
        end
      )

    ## At this point, we have a sequence of sets of tools
    ## that corresponds to the sequence of jobs.
    ## The number of switches when moving to next job
    ## is a difference between the next and current tool sets.
    Enum.reduce(0..(length(magazine_sequence) - 2), 0, fn j, acc ->
      magazine_state = Enum.at(magazine_sequence, j)
      next_magazine_state = Enum.at(magazine_sequence, j + 1)
      acc + MapSet.size(MapSet.difference(next_magazine_state, magazine_state))
    end)
  end

  ## Optimize switches given the sequence of jobs.
  ## That's what TLP (Tool Loading Problem) solves:
  ## (Tang, Denardo) Given the job sequence, find the optimal sequence
  ## of magazine states that minimizes the total number of tool switches
  def optimize_switches(instance_data, schedule, opts \\ default_solver_opts()) do
    solution_constraint = {:model_text, schedule_constraint(schedule)}
    {:ok, model_results} =
      JSTSP.run_model(instance_data,
        model: [solution_constraint | opts[:model]],
        symmetry_breaking: false,
        solver: "cplex"
      )

    count_switches(model_results.schedule, model_results.magazine)

  end
  def ignore_symmetry_flag(bool \\ false) do
    "-D mzn_ignore_symmetry_breaking_constraints=#{bool}"
  end

  def mzn_dir_flag(dir \\ mzn_dir()) do
    "-I #{dir}"
  end

  def inline_model(model_text) do
    {:model_text, model_text && model_text || ""}
  end

  defp to_toolset(tools) do
    tools
    |> Enum.with_index(1)
    |> Enum.flat_map(fn
      {1, idx} -> [idx]
      {0, _idx} -> []
    end)
    |> MapSet.new()
  end

  def to_matrix(jobs) do
    m = Enum.max(List.flatten(jobs))

    Enum.map(
      jobs,
      fn job -> Enum.map(1..m, fn i -> (i in job && 1) || 0 end) end
    )
  end

  @doc """
    Definition: the job A is dominated by job B <=> A is a subset of B.
    Computes the list of {dominated, by} tuples.
  """
  @spec dominant_jobs([[non_neg_integer()]]) :: [{dominated :: non_neg_integer(), by :: non_neg_integer()}]
  def dominant_jobs(jobs) do
    Enum.max(List.flatten(jobs)) <= 1 && dominant_jobs_impl(jobs)
    || dominant_jobs_impl(to_matrix(jobs))
  end

  defp dominant_jobs_impl(job_matrix) do
    sorted_job_matrix =
      job_matrix
      |> Enum.with_index(1)
      |> Enum.sort_by(fn {job, _idx} -> {Enum.sum(job), job} end)

    Enum.reduce(0..(length(sorted_job_matrix) - 2), [], fn pos, acc ->
      {current_job, current_idx} = Enum.at(sorted_job_matrix, pos)

      Enum.reduce_while((pos + 1)..(length(sorted_job_matrix) - 1), acc, fn next_pos, acc2 ->
        {next_job, next_idx} = Enum.at(sorted_job_matrix, next_pos)

        (Enum.all?(Enum.zip(next_job, current_job), fn {n, c} -> n >= c end) &&
           {:halt, [{current_idx, next_idx} | acc2]}) || {:cont, acc2}
      end)
    end)

  end
  @doc """
    Purpose:
    The schedule is a solution of the problem, reduced by removing
    dominated jobs (Yanasse, Senne, 2009).
    We want to merge dominated jobs back in by putting each of them
    after their dominant jobs (as obviously this won't change the switch count).
  """
  def merge_dominated(schedule, dominant_jobs) do
    dominance_map = Enum.group_by(dominant_jobs,
      fn {_d, by} -> by end, fn {d, _by} -> d end)
      schedule
      |> merge_dominated_impl(dominance_map)
  end

  @doc """
  Purpose: build the warmup schedule by putting the partial schedule
  (obtained for example, with set-cover method) in front
  """
  def warmup_schedule(schedule, partial_schedule) do
    normalize_schedule(
    partial_schedule ++
      Enum.reduce(partial_schedule, schedule, fn el, acc -> List.delete(acc, el) end)
    )
  end

  defp merge_dominated_impl(schedule, dominance_map) when map_size(dominance_map) == 0 do
    schedule
  end

  defp merge_dominated_impl(schedule, dominance_map) do
    {dominance_map, schedule} = Enum.reduce(schedule, {dominance_map, []},
    fn job_idx, {reduced_map, merged_schedule} = _acc ->
      merged = merged_schedule ++ [job_idx | Map.get(reduced_map, job_idx, [])]
      {Map.delete(reduced_map, job_idx), merged}
    end)
    merge_dominated_impl(schedule, dominance_map)

  end
end
