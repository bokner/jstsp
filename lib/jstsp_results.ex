defmodule JSTSP.Results do
  require Logger
  def update_results(results_csv, opts) do
    results_csv
    |> parse_results()
    |> Enum.reject(fn rec -> rec.status == "optimal" end)
    |> tap(fn instances ->
      :erlang.put(:instance_num, length(instances))
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {rec, idx} ->
      Logger.info("Instance: #{rec.instance} (#{idx} of #{:erlang.get(:instance_num)})")
      JSTSP.run(rec.instance, Keyword.put(opts, :upper_bound, rec.objective))
    end)
  end

  def parse_results(csv_results) do
    csv_results
    |> File.stream!
    |> CSV.decode(headers: true)
    |> Enum.map(fn {:ok, rec} ->
      %{
        instance: rec["instance"],
        objective: String.to_integer(rec["objective"]),
        status: rec["status"],
        schedule: rec["schedule"],
        T: String.to_integer(rec["T"]),
        J: String.to_integer(rec["J"]),
        C: String.to_integer(rec["C"]),
        solver: rec["solver"]
      }
      end)
  end
end
