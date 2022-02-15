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
      cover_lb: 10, ## minimum length of set cover
    ] |> build_extra_flags()
  end

  def job_cover(instance, opts \\ [])

  def job_cover(instance, opts) when is_binary(instance) do
    instance
    |> get_instance_data()
    |> job_cover(opts)
  end

  def job_cover(instance_data, opts) when is_map(instance_data) do
    solver_opts =
      default_set_cover_opts()
      |> Keyword.merge(opts)
      |> Keyword.put(:solution_handler, default_set_cover_opts()[:solution_handler])
      |> Keyword.put(:solver, default_set_cover_opts()[:solver])

    model =
    default_set_cover_opts()[:model]
    |> adjust_model_paths(
      solver_opts[:mzn_dir]
      )
    case MinizincSolver.solve_sync(model, build_setcover_data(instance_data, opts), solver_opts) do
      {:ok, res} ->
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
      {:error, error} -> {:error, error}
    end
  end

  defp build_setcover_data(instance_data, opts) do
    cover_lb = Keyword.get(opts, :cover_lb, default_set_cover_opts()[:cover_lb])
    instance_data
    |> Map.take([:T, :J, :job_tools])
    |> Map.put(:cover_lb, cover_lb)
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
      |> then(fn cover -> cover && Enum.sum(cover) || 0 end)

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
