defmodule JSTSP.Utils do
  require Logger

  def default_solver_opts do
    [
      solver: "cplex",
      solution_handler: JSTSP.MinizincHandler,
      time_limit: 300_000,
      model: "jstsp.mzn"
    ]
  end

  def instance_data(instance_file) do
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

  defp transpose(matrix) do
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
    "#{instance},#{jobs},#{tools},#{capacity},#{solver},#{time_limit},#{status},#{objective},\"#{inspect(schedule)}\""
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

  def schedule_constraint(schedule) do
    "constraint schedule = #{inspect(schedule)};"
  end

  def count_switches(schedule, magazine) do
    magazine_sequence =
      Enum.map(
        0..(length(schedule) - 1),
        fn i ->
          magazine
          |> Enum.at(Enum.at(schedule, i) - 1)
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

  @spec dominant_jobs([[0 | 1]]) :: [any()]
  def dominant_jobs(job_matrix) do
    sorted_job_matrix =
      Enum.sort_by(Enum.with_index(job_matrix, 1), fn {job, _idx} -> {Enum.sum(job), job} end)

    Enum.reduce(0..(length(sorted_job_matrix) - 2), [], fn pos, acc ->
      {current_job, current_idx} = Enum.at(sorted_job_matrix, pos)

      Enum.reduce_while((pos + 1)..(length(sorted_job_matrix) - 1), acc, fn next_pos, acc2 ->
        {next_job, next_idx} = Enum.at(sorted_job_matrix, next_pos)

        (Enum.all?(Enum.zip(next_job, current_job), fn {n, c} -> n >= c end) &&
           {:halt, [{current_idx, next_idx} | acc2]}) || {:cont, acc2}
      end)
    end)
  end
end
