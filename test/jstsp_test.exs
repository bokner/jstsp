defmodule JstspTest do
  use ExUnit.Case
  doctest JSTSP

  import JSTSP.Utils

  require Logger

  test "check the model output" do
    model = Path.join([:code.priv_dir(:jstsp), "mzn", "jstsp.mzn"])
    data_instance = Path.join([:code.priv_dir(:jstsp), "mzn", "da_silva1.dzn"])
    {:ok, res} = MinizincSolver.solve_sync(model, data_instance, solver: "gecode")

    model_results =
      res
      |> MinizincResults.get_last_solution()
      |> then(fn solution ->
        %{
          schedule: MinizincResults.get_solution_value(solution, "schedule"),
          magazine: MinizincResults.get_solution_value(solution, "magazine"),
          objective: MinizincResults.get_solution_objective(solution)
        }
      end)

    switches = count_switches(model_results.schedule, model_results.magazine)
    assert switches == model_results.objective
  end

  defp jstsp_sample() do
    %{
      job_tools: [
        [1, 0, 0, 1, 0, 0, 0, 1, 1],
        [1, 0, 1, 0, 1, 0, 0, 0, 0],
        [0, 1, 0, 0, 0, 1, 1, 1, 0],
        [1, 0, 0, 0, 1, 0, 1, 0, 1],
        [0, 0, 1, 0, 1, 0, 0, 1, 0],
        [1, 1, 0, 1, 0, 0, 0, 0, 0]
      ],
      C: 4
    }
  end
end
