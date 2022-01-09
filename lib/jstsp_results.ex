defmodule JSTSP.Results do
  require Logger
  import JSTSP.Utils
  import JSTSP

  def update_results(results_csv, opts) do
    prev_results = parse_results(results_csv)

    prev_results
    |> Enum.reject(fn rec -> rec.status == "optimal" end)
    |> tap(fn instances ->
      :erlang.put(:instance_num, length(instances))
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {rec, idx} ->
      Logger.info("Instance: #{rec.instance} (#{idx} of #{:erlang.get(:instance_num)})", ansi_color: :green)
      instance_data = get_instance_data(rec.instance)
      opts =
        Keyword.get(opts, :methods, [:upper_bound])
        |> Enum.reduce(opts, fn update_option, acc ->

        Keyword.put(acc, update_option, update_option_arg(update_option, instance_data, rec, opts)) end)
      JSTSP.run_model(instance_data, opts)
      |> Map.put(:instance, rec.instance)
    end)
    |> merge_results(prev_results)
  end

  defp update_option_arg(:upper_bound, _data, rec, _opts) do
    rec.objective
  end

  defp update_option_arg(:warm_start, _data, rec, _opts) do
    %{schedule: rec.schedule}
  end

  defp update_option_arg(:lower_bound, data, _rec, _opts) do
    get_lower_bound(data).lower_bound
  end

  def parse_results(csv_results) do
    csv_results
    |> File.stream!()
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
        solver: rec["solver"],
        time_limit: rec["time_limit(msec)"]
      }
    end)
  end

  def merge_results(new_results, prev_results) do
    new_results_by_instance = Enum.group_by(new_results, & &1.instance)
    Enum.map(prev_results,
      fn rec -> optimal?(rec.status) &&
        rec || (
          [new_rec] = Map.get(new_results_by_instance, rec.instance)
          (optimal?(new_rec.status) || new_rec.objective < rec.objective)
        &&
         tap(new_rec, fn better ->
           Logger.warn("Better solution found: #{inspect better}")
         end)
        || rec)
      end)
  end

  defp optimal?(status) do
    to_string(status) == "optimal"
  end

  def get_lower_bounds(csv_results) do
    csv_results
    |> parse_results()
    |> tap(fn instances ->
      :erlang.put(:instance_num, length(instances))
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {rec, idx} ->
      Logger.info("Instance: #{rec.instance} (#{idx} of #{:erlang.get(:instance_num)})")
      data = get_instance_data(rec.instance)
      {rec.instance,
      JSTSP.get_lower_bound(data),
      JSTSP.get_trivial_lower_bound(data)} end)
  end
  def yanasse_beam_search_results() do
    obks = [
      %{instance: "L22-3", obks: 18, our: 22, ys: 18.2},
      %{instance: "L22-4", obks: 15, our: 16, ys: 17},
      %{instance: "L22-5", obks: 17, our: 19, ys: 17},
      %{instance: "L22-6", obks: 15, our: 17, ys: 16},
      %{instance: "L22-8", obks: 19, our: 21, ys: 19.6},
      %{instance: "L22-9", obks: 18, our: 19, ys: 18},
      %{instance: "L22-10", obks: 16, our: 19, ys: 17},
      %{instance: "L23-2", obks: 10, our: 10, ys: 10},
      %{instance: "L23-3", obks: 10, our: 11, ys: 11},
      %{instance: "L25-6", obks: 5, our: 5, ys: 6}
    ]

    Enum.map(obks, fn {name, _value} ->
      "instances/MTSP/Laporte/Tabela6/#{name}.txt"
    end)
  end
end
