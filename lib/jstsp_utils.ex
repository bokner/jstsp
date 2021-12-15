defmodule JSTSP.Utils do
  require Logger

  def default_solver_opts do
    [
      solver: "gecode",
      solution_handler: JSTSP.MinizincHandler,
      time_limit: 30_000,
      model: "jstsp.mzn"
    ]
  end

  def parse_instance(instance_file) do
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
        fn %{instance: instance, results: solver_results}, acc ->
          acc ++
            Enum.map(
              solver_results,
              fn %{
                   T: tools,
                   J: jobs,
                   C: capacity,
                   solver: solver,
                   time_limit: time_limit,
                   status: status,
                   objective: objective,
                   schedule: schedule
                 } ->
                "#{instance},#{jobs},#{tools},#{capacity},#{solver},#{time_limit},#{status},#{objective},\"#{inspect(schedule)}\""
              end
            )
        end
      )
      |> Enum.join("\n")
      |> then(fn content -> File.write(filename, content) end)
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
end
