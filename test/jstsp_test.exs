defmodule JstspTest do
  use ExUnit.Case
  doctest JSTSP

  import JSTSP.Utils

  require Logger

  test "check the model output" do
    model = Path.join([:code.priv_dir(:jstsp), "mzn", "jstsp.mzn"])
    data_instance = Path.join([:code.priv_dir(:jstsp), "mzn", "da_silva1.dzn"])

    {:ok, res} =
      MinizincSolver.solve_sync(model, data_instance,
        solver: "gecode",
        solution_handler: JSTSP.MinizincHandler
      )

    model_results = model_results(res)

    switches = count_switches(model_results.schedule, model_results.magazine)
    assert switches == model_results.objective
  end

  test "Yanasse, Senne" do
    sample = jstsp_set_sample()
    our_schedule = [2, 9, 10, 1, 11, 14, 8, 4, 6, 12, 15, 13, 7, 3, 5]
    solution_constraint = {:model_text, schedule_constraint(our_schedule)}
    m = Enum.max(List.flatten(sample.jobs))

    job_tools =
      Enum.map(
        sample.jobs,
        fn job -> Enum.map(1..m, fn i -> (i in job && 1) || 0 end) end
      )

    data = %{C: 10, J: 15, T: 15, job_tools: job_tools}
    model = Path.join([:code.priv_dir(:jstsp), "mzn", "jstsp.mzn"])

    {:ok, mzn_results} =
      MinizincSolver.solve_sync([model, solution_constraint], data,
        solver: "cplex",
        solution_handler: JSTSP.MinizincHandler,
        time_limit: 150_000
      )

    model_results = model_results(mzn_results)

    switches = count_switches(model_results.schedule, model_results.magazine)
    assert switches == model_results.objective
    ## The optimal value claimed by Yanasse, Senne
    assert model_results.objective == 13
    ## ... is obtained by our model with different schedule
    assert model_results.schedule == our_schedule
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

  ## Sample from Yanasse, Senne paper
  def jstsp_set_sample() do
    %{
      C: 10,
      jobs: [
        [3, 7, 10, 11],
        [1, 3, 5, 8, 11],
        [2, 5, 9, 11, 14],
        [7, 8, 9, 11, 13, 14],
        [1, 4, 5, 11, 12, 14],
        [2, 3, 5, 7, 11, 13],
        [1, 2, 5, 8, 10, 11, 12],
        [4, 7, 8, 11, 12, 13, 14],
        [1, 3, 5, 6, 7, 9, 11, 15],
        [1, 4, 5, 6, 7, 8, 9, 10],
        [4, 5, 7, 8, 9, 10, 11, 13],
        [2, 3, 4, 5, 9, 10, 13, 14, 15],
        [1, 2, 5, 8, 9, 10, 12, 14, 15],
        [3, 4, 5, 6, 8, 9, 11, 12, 13, 14],
        [1, 2, 4, 7, 9, 10, 12, 13, 14, 15]
      ],
      schedule: [3, 12, 6, 11, 1, 8, 4, 14, 5, 9, 2, 10, 7, 13, 15]
    }
  end

  defp model_results(mzn_results) do
    mzn_results
    |> MinizincResults.get_last_solution()
    |> then(fn solution ->
      %{
        schedule: MinizincResults.get_solution_value(solution, "schedule"),
        magazine: MinizincResults.get_solution_value(solution, "magazine"),
        objective: MinizincResults.get_solution_objective(solution)
      }
    end)
  end
end
