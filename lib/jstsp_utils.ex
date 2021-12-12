defmodule JSTP.Utils do
  def to_csv(results, filename) do
    header = "instance,J,T,C,solver,status,objective,schedule"
    :ok =
    results
    |> Enum.reduce([header],
      fn %{instance: instance, results: solver_results}, acc ->
        acc ++ Enum.map(solver_results,
        fn %{
          T: tools,
          J: jobs,
          C: capacity,
          solver: solver,
          status: status,
          objective: objective,
          schedule: schedule
          } ->
          "#{instance},#{jobs},#{tools},#{capacity},#{solver},#{status},#{objective},#{inspect schedule}"
        end)
      end)
    |> Enum.join("\n")
    |> then(fn content -> File.write(filename, content) end)
  end
  def count_switches(schedule, job_tool_matrix) do
    Enum.reduce(0..length(schedule) - 1, 0,
    fn idx, acc ->
      job = Enum.at(schedule, idx)
      next_job = Enum.at(schedule, idx + 1)
      acc + switches_next_job(job, next_job, job_tool_matrix)
    end)
  end

  defp switches_next_job(job, next_job, job_tool_matrix) do
    job_tools = job_tools(job, job_tool_matrix)
    next_job_tools = job_tools(next_job, job_tool_matrix)

    next_job_tools
    |> MapSet.difference(job_tools)
    |> MapSet.size()
  end

  defp job_tools(job, job_tool_matrix) do
    job_tool_matrix
    |> Enum.at(job)
    |> Enum.with_index()
    |> Enum.flat_map(
      fn ({0, _idx}) -> []
          ({1, idx}) -> [idx]
      end)
    |> MapSet.new()
  end

end
