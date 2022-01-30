defmodule SSP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      %{
      id: :ssp_cubdb,
      start: {SSP.Application, :start_db, []}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SSP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_db() do
    {:ok, _db} = CubDB.start_link(
      data_dir: Path.join(:code.priv_dir(:ssp), "cubdb"),
      name: :cubdb)

  end

end
