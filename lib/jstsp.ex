defmodule JSTSP do
  @moduledoc """
  Module for solving JSTSP instances.
  """


  def run(instance, opts \\ [])

  def run(instance_file, opts) when is_binary(instance_file) do
    instance_file
    |> parse_instance()
    |> run_model(opts)
  end

  def parse_instance(instance_file) do
    parsed_data =
    instance_file
    |> File.read!()
    |> String.split("\r\n", trim: true)
    |> Enum.map(fn line ->
      line
      |> String.split(" ")
      |> Enum.map(fn numstr -> String.to_integer(numstr) end)
    end)
    [[j, t, c] | job_tool_matrix] = parsed_data
    job_tool_matrix = transpose(job_tool_matrix)

    # Check if the JT matrix matches the sizes claimed by the instance
    true = (j == length(job_tool_matrix) && (t == length(hd(job_tool_matrix))))

    %{
      T: t,
      J: j,
      C: c,
      job_tools: job_tool_matrix
    }

  end

  @doc """
  Run the model on a problem instance
  """
  def run_model(instance, opts \\ [])

  def run_model(data_instance, solver_opts) do
    solver_opts = Keyword.merge(default_solver_opts(), solver_opts)

    MinizincSolver.solve_sync(get_model(solver_opts), data_instance, solver_opts)
  end

  defp get_model(opts) do
    Path.join([:code.priv_dir(:jstsp), "mzn", Keyword.get(opts, :model)])
  end

  defp transpose(matrix) do
    matrix
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  def default_solver_opts do
    [
      solver: "gecode",
      solution_handler: JSTSP.MinizincHandler,
      time_limit: 30_000,
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
