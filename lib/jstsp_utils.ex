defmodule JSTP.Utils do
  def to_csv(results, filename) do
    header = "instance,solver,status,objective,schedule"
    :ok =
    results
    |> Enum.reduce([header],
      fn %{instance: instance, results: solver_results}, acc ->
        acc ++ Enum.map(solver_results,
        fn %{solver: solver, status: status, objective: objective, schedule: schedule} ->
          "#{instance},#{solver},#{status},#{objective},#{inspect schedule}"
        end)
      end)
    |> Enum.join("\n")
    |> then(fn content -> File.write(filename, content) end)
  end

end
