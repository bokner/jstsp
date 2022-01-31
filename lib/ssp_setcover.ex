defmodule SSP.SetCover do

  import SSP.Utils
  alias SSP.Minizinc.SetCoverHandler
  def default_set_cover_opts do
    [
      solver: "cplex",
      solution_handler: SetCoverHandler,
      time_limit: 300_000,
      mzn_dir: mzn_dir(),
      model: "setcover.mzn",
    ] |> build_extra_flags()
  end

  def job_cover(instance, opts \\ [])

  def job_cover(instance, opts) when is_binary(instance) do
    instance
    |> get_instance_data()
    |> job_cover(opts)
  end

  def job_cover(instance_data, opts) when is_map(instance_data) do
    solver_opts = Keyword.merge(opts, default_set_cover_opts())
    model = solver_opts[:model]
    |> adjust_model_paths()
    {:ok, res} = MinizincSolver.solve_sync(model, build_data(instance_data), solver_opts)

    res
    |> MinizincResults.get_last_solution()
    |> then(fn solution ->
      %{
        solver: res.summary.solver,
        time_limit: solver_opts[:time_limit],
        objective: MinizincResults.get_solution_objective(solution),
        status: MinizincResults.get_status(res.summary),
        cover: MinizincResults.get_solution_value(solution, "cover")
      }
    end)
    |> Map.merge(instance_data)
  end
end

defmodule SSP.Minizinc.SetCoverHandler do
  @moduledoc false

  require Logger
  alias MinizincHandler.Default, as: DefaultHandler
  use MinizincHandler

  @doc false
  def handle_summary(summary) do
    cover_size =
      summary
      |> MinizincResults.get_last_solution()
      |> MinizincResults.get_solution_value("cover")
      |> Enum.sum()
    Logger.debug(
      "SET COVER: final status (#{summary.solver}): #{summary.status}, cover size: #{cover_size}"
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
