defmodule JSTSP do
  @moduledoc """
  Module for solving JSTSP instances.
  """

  @doc """
  Run the model on a problem instance
  """
  #def run_model(instance, \\ [])

  def run_model(_instance =
    %{magazine_size: magazine_size, job_tools: job_tool_matrix}, solver_opts) do
    solver_opts = Keyword.merge(default_solver_opts(), solver_opts)
    number_of_tools = length(hd(job_tool_matrix))
    number_of_jobs = length(job_tool_matrix)
    data = %{
      T: number_of_tools,
      J: number_of_jobs,
      C: magazine_size,
      job_tools: job_tool_matrix
    }
    MinizincSolver.solve_sync(get_model(solver_opts), data, solver_opts)
  end

  defp get_model(opts) do
    Keyword.get(opts, :model)
  end

  def default_solver_opts do
    [
      solver: "gecode",
      solution_handler: JSTSP.MinizincHandler,
      time_limit: 25_000,
      model: "jstsp.mzn"
    ]
  end
end

defmodule JSTSP.MinizincHandler do
  @moduledoc false

  require Logger
  alias MinizincHandler.Default, as: DefaultHandler
  use MinizincHandler

  @doc false
  def handle_solution(solution = %{index: _count, data: _data}) do
    Logger.info(
      "Objective: #{MinizincResults.get_solution_objective(solution)}"
    )

    DefaultHandler.handle_solution(solution)
  end

  @doc false
  def handle_summary(summary) do
    Logger.info("MZN final status: #{summary[:status]}")
    DefaultHandler.handle_summary(summary)
  end

  @doc false
  def handle_minizinc_error(error) do
    Logger.info("Minizinc error: #{inspect(error)}")
    DefaultHandler.handle_minizinc_error(error)
  end
end
