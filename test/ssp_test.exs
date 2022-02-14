defmodule SSPTest do
  use ExUnit.Case
  doctest SSP

  import SSP.Utils

  require Logger

  setup do
    %{mzn_dir: mzn_dir()}
  end

  test "check the model output", %{mzn_dir: mzn_dir} do

    data_instance = Path.join([mzn_dir, "da_silva1.dzn"])

    {:ok, model_results} =
      SSP.run_model(data_instance,
        mzn_dir: mzn_dir,
        model: standard_model(),
        solver: "gecode",
        solution_handler: SSP.MinizincHandler
      )

    switches = count_switches(model_results.sequence, model_results.magazine)
    assert switches == model_results.objective
  end

  test "Yanasse, Senne (1)", %{mzn_dir: mzn_dir} do
    sample = ssp_set_sample1()
    our_sequence = [2, 9, 10, 1, 11, 14, 8, 4, 6, 12, 15, 13, 7, 3, 5]
    solution_constraint = {:model_text, sequence_constraint(our_sequence)}
    job_tools = to_matrix(sample.jobs)

    data =
      sample
      |> Map.take([:C, :T, :J])
      |> Map.put(:job_tools, job_tools)

    {:ok, model_results} =
      SSP.run_model(data,
        mzn_dir: mzn_dir,
        solver: "cplex",
        model: [solution_constraint | standard_model()],
        solution_handler: SSP.MinizincHandler,
        time_limit: 150_000
      )

    ys_optimal = 13
    switches = count_switches(model_results.sequence, model_results.magazine)
    assert switches == model_results.objective
    ## The optimal value claimed by Yanasse, Senne
    assert model_results.objective == ys_optimal
    ## ... is obtained by our model with different sequence
    assert model_results.sequence == our_sequence
  end

   test "Yanasse, Senne (2)", %{mzn_dir: mzn_dir} do
    sample = ssp_set_sample2()
    job_tools = to_matrix(sample.jobs)

    ys_optimal = 13
    data =
      sample
      |> Map.take([:C, :T, :J])
      |> Map.put(:job_tools, job_tools)

    ## The optimal value claimed by Yanasse, Senne
    assert_sequence(sample.sequence, data, ys_optimal)
  end

  @tag timeout: 300_000
  test "dominant/dominated jobs", %{mzn_dir: mzn_dir} do
    ## Following Y/S example ('An enumeration algorithm....')
    ys_optimal = 13 ## The optimal value claimed by Y/S
    sample = ssp_set_sample2()
    full_job_list = sample.jobs
    dominant_jobs = dominant_jobs(full_job_list)
    dominated =
      dominant_jobs
      |> Enum.map(fn {d, _by} -> d end)
      |> Enum.uniq()

    reduced_list = Enum.reject(sample.sequence, fn f -> f in dominated end)
    assert length(dominated) == 10
    assert length(reduced_list) == 15
    ## Merge dominated jobs into the reduced sequence
    full_sequence = merge_dominated(reduced_list, dominant_jobs)
    assert length(full_sequence) == 25
    ## Validate the full sequence
    data =
      sample
      |> Map.take([:C, :T, :J])
      |> Map.put(:job_tools, to_matrix(full_job_list))

    assert_sequence(full_sequence, data, ys_optimal)
    ## Run model with reduced job list
    reduced_job_list =
    full_job_list
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {job, idx} -> idx in reduced_list && [job] || [] end)
    |> to_matrix()

    data =
      sample
      |> Map.take([:C, :T])
      |> Map.put(:J, length(reduced_job_list))
      |> Map.put(:job_tools, reduced_job_list)
    {:ok, model_results} = SSP.run_model(data,
        solver: "cplex",
        #symmetry_breaking: false,
        mzn_dir: mzn_dir,
        solution_handler: SSP.MinizincHandler,
        time_limit: 180_000,
        warm_start: %{sequence: reduced_list},
        #upper_bound: ys_optimal + 5,
        lower_bound: ys_optimal
      )

    assert model_results.objective == ys_optimal
  end

  test "set cover" do
    instance = "instances/MTSP/Crama/Tabela1/s4n009.txt"
    cover_results = SSP.SetCover.job_cover(instance, mzn_dir: "priv/mzn-sets", cover_lb: 8)
    cover = cover_results.cover
    jobs = cover_results.job_tools
    cover_jobs = Enum.flat_map(0..length(cover) - 1,
      fn pos -> Enum.at(cover, pos) == 1 && [Enum.at(jobs, pos)]
        || []
    end)
    tool_matrix = SSP.Utils.transpose(cover_jobs)
    ## All tools are covered by job set cover...
    assert Enum.all?(tool_matrix, fn tool -> Enum.sum(tool) > 0 end)
    ## ... and any reduction of job set cover does not cover it
    ## (that is, the cover cannot be reduced to its subset)

    ### !!!! This was true for the minimal cover
    ### We now have extended cover

    #Enum.each(0..length(cover_jobs) - 1, fn pos ->
    #    refute Enum.all?(tool_matrix, fn tool -> Enum.sum(List.delete_at(tool, pos)) > 0
    #  end)
    #end)
    assert length(cover_jobs) == 8

  end

  @tag timeout: 180_000
  test "lower bound on set cover" do

    instance = "instances/MTSP/Crama/Tabela1/s4n009.txt"
    data = get_instance_data(instance)
    lb = SSP.get_lower_bound(data, mzn_dir: "priv/mzn-sets", cover_lb: 8)

    ## Lower bound based on set-cover method
    assert lb.lower_bound == 58
    ## Trivial lower bound
    assert SSP.get_trivial_lower_bound(data) == 40

  end

  defp ssp_sample() do
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
  def ssp_set_sample1() do
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
      sequence: [3, 12, 6, 11, 1, 8, 4, 14, 5, 9, 2, 10, 7, 13, 15]
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
  def ssp_set_sample2() do
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
      sequence: [11, 22,
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
      ]}
  end

  defp assert_sequence(sequence, data, objective) do
    assert optimize_switches(data, sequence) == objective
  end
end
