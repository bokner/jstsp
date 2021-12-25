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

  test "Yanasse, Senne (1)" do
    sample = jstsp_set_sample1()
    our_schedule = [2, 9, 10, 1, 11, 14, 8, 4, 6, 12, 15, 13, 7, 3, 5]
    solution_constraint = {:model_text, schedule_constraint(our_schedule)}
    job_tools = to_matrix(sample.jobs)

    data =
      sample
      |> Map.take([:C, :T, :J])
      |> Map.put(:job_tools, job_tools)

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

   test "Yanasse, Senne (2)" do
    sample = jstsp_set_sample2()
    our_schedule = [11, 15, 6, 14, 18, 1, 12, 9, 3, 20, 5, 17, 2, 10, 4, 7, 8, 16, 13, 19]
    job_tools = to_matrix(sample.jobs)

    data =
      sample
      |> Map.take([:C, :T, :J])
      |> Map.put(:job_tools, job_tools)

    solution_constraint = {:model_text, schedule_constraint(sample.schedule)}
    model = Path.join([:code.priv_dir(:jstsp), "mzn", "jstsp.mzn"])
    {:ok, mzn_results} =
      MinizincSolver.solve_sync([model, solution_constraint], data,
        solver: "cplex",
        solution_handler: JSTSP.MinizincHandler,
        time_limit: 1200_000
      )

    model_results = model_results(mzn_results)

    switches = count_switches(model_results.schedule, model_results.magazine)
    assert switches == model_results.objective
    ## The optimal value claimed by Yanasse, Senne
    assert model_results.objective == 13
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

  ## Yanasse, Senne (Beam Search paper)
  def jstsp_set_sample1() do
    %{
      C: 10,
      J: 15,
      T: 15,
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

  ## Yanasse, Senne (https://www.researchgate.net/publication/262710640)
  # J = 25, T = 15, C = 10
  # T1 = {1,2}
  # T2 = {5,15}
  # T3 = {4,7,11}
  # T4 = {2,8,9}
  # T5 = {5,13,15}
  # T6 = {1,7,9,13}
  # T7 = {3,7,10,11}
  # T8 = {4,5,7,8,9}
  # T9 = {2,7,9,10,15}
  # T10 = {1,3,5,8,11}
  # T11 = {2,5,9,11,14}
  # T12 = {7,8,9,11,13,14}
  # T13 = {1,4,5,11,12,14}
  # T14 = {2,3,5,7,11,13}
  # T15 = {1,4,6,8,9,10}
  # T16 = {1,2,5,8,10,11,12}
  # T17 = {3,4,5,6,8,9,11}
  # T18 = {4,7,8,11,12,13,14}
  # T19 = {1,3,5,6,7,9,11,15}
  # T20 = {1,4,5,6,7,8,9,10}
  # T21 = {4,5,7,8,9,10,11,13}
  # T22 = {2,3,4,5,9,10,13,14,15}
  # T23 = {1,2,5,8,9,10,12,14,15}
  # T24 = {3,4,5,6,8,9,11,12,13,14}
  # T25 = {1,2,4,7,9,10,12,13,14,15}
  def jstsp_set_sample2() do
    jobs = [
      [1, 2],
      [5, 15],
      [4, 7, 11],
      [2, 8, 9],
      [5, 13, 15],
      [1, 7, 9, 13],
      [3, 7, 10, 11],
      [4, 5, 7, 8, 9],
      [2, 7, 9, 10, 15],
      [1, 3, 5, 8, 11],
      [2, 5, 9, 11, 14],
      [7, 8, 9, 11, 13, 14],
      [1, 4, 5, 11, 12, 14],
      [2, 3, 5, 7, 11, 13],
      [1, 4, 6, 8, 9, 10],
      [1, 2, 5, 8, 10, 11, 12],
      [3, 4, 5, 6, 8, 9, 11],
      [4, 7, 8, 11, 12, 13, 14],
      [1, 3, 5, 6, 7, 9, 11, 15],
      [1, 4, 5, 6, 7, 8, 9, 10],
      [4, 5, 7, 8, 9, 10, 11, 13],
      [2, 3, 4, 5, 9, 10, 13, 14, 15],
      [1, 2, 5, 8, 9, 10, 12, 14, 15],
      [3, 4, 5, 6, 8, 9, 11, 12, 13, 14],
      [1, 2, 4, 7, 9, 10, 12, 13, 14, 15]
    ]

    %{
      J: length(jobs),
      T: 15,
      C: 10,
      jobs: jobs,
      schedule: Enum.reverse([11, 22,
      5, 2, ## dominated jobs
      14, 21,
      8, ## dominated
      7, 18,
      3, ## dominated
      12, 24,
      17, ## dominated
      13, 19, 10, 20,
      15, ## dominated
      16,
      1, ## dominated
      23,
      4, ## dominated,
      25,
      6, 9 ## dominated
      ])}
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
