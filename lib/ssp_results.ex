defmodule SSP.Results do
  require Logger
  import SSP.Utils
  import SSP

  def update_results(results_csv, opts) do
    prev_results = parse_results(results_csv)
    filter_fun = Keyword.get(opts, :filter, fn x -> x end)

    prev_results
    |> Enum.reject(fn rec -> rec.status == :optimal end)
    |> filter_fun.()
    |> tap(fn instances ->
      :erlang.put(:instance_num, length(instances))
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {rec, idx} ->
      Logger.info("Instance: #{rec.instance} (UB = #{rec.objective}) (#{idx} of #{:erlang.get(:instance_num)})", ansi_color: :green)
      instance_data = get_instance_data(rec.instance)
      opts =
        Keyword.get(opts, :methods, [:upper_bound])
        |> Enum.reduce(opts, fn update_option, acc ->

        Keyword.put(acc, update_option, update_option_arg(update_option, instance_data, rec, opts)) end)

      case SSP.run_model(instance_data, opts) do
        {:ok, new_result} ->
          choose_best(new_result, rec)
        {:error, error} ->
          Logger.error("Error on #{inspect rec.instance} : #{inspect error}")
          rec
      end
    end)
    |> Enum.group_by(fn rec -> rec.instance end)
    |> then(fn new_results_by_instance ->
      Enum.map(parse_results(results_csv),
        fn rec -> new_result = Map.get(new_results_by_instance, rec.instance)
         new_result && hd(new_result) || rec end)
    end
    )
  end

  defp update_option_arg(:upper_bound, _data, rec, _opts) do
    rec.objective
  end

  defp update_option_arg(:warm_start, _data, _rec = %{sequence: sequence_str}, _opts) do
    {sequence, _} = Code.eval_string(sequence_str)
    %{sequence: normalize_sequence(sequence)}
  end

  defp update_option_arg(:lower_bound, data, _rec, opts) do
    get_lower_bound(data, opts).lower_bound
  end

  def parse_results(csv_results) do
    fields = [
      :instance, :objective, :status,
      :sequence, :T, :J, :C, :solver, :time_limit
    ]
    csv_results
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Enum.map(fn {:ok, rec} ->
      Enum.reduce(fields, %{}, fn field, acc ->
        value = rec["#{field}"]
        value && Map.put(acc, field, parse_field(field, value))
        || acc end)
    end)
  end

  defp parse_field(field, value) when field in [:objective, :T, :J, :C, :time_limit] do
    String.to_integer(value)
  end

  defp parse_field(:status, value) do
    String.to_atom(value)
  end

  defp parse_field(_field, value) do
    value
  end

  def parse_lower_bounds(lb_csv) do
    lb_csv
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Enum.map(fn {:ok, rec} ->
      %{
        instance: rec["instance"],
        lower_bound: String.to_integer(rec["lower_bound"]),
        partial_sequence: rec["partial_sequence"]
      }
    end)
  end


  def choose_best(new_result, prev_result) do
      optimal?(prev_result) && prev_result
        || (
          success?(new_result) && (optimal?(new_result) || new_result.objective < prev_result.objective)
        &&
         tap(new_result, fn better ->
           Logger.warn("Better solution found: #{inspect better}")
         end)
        || prev_result)
  end

  def merge_results(csv_results, new_results) when is_binary(csv_results) do
    prev_results = parse_results(csv_results)
    merged = merge_results(prev_results, new_results)
    to_csv(merged, csv_results)
  end

  def merge_results(prev_results, new_results) do
    Enum.map(Enum.zip(prev_results, new_results),
      fn {prev, new} -> SSP.Results.choose_best(prev, new) end)
  end

  defp success?(result) do
    !Map.has_key?(result, :error)
  end

  defp optimal?(result) do
    result.status == :optimal
  end

  def get_lower_bounds(csv_results, opts \\ []) do
    opts = Keyword.merge(default_solver_opts(), opts)
    csv_results
    |> parse_results()
    |> Enum.reject(fn rec -> optimal?(rec) end)
    |> tap(fn instances ->
      :erlang.put(:instance_num, length(instances))
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {rec, idx} ->
      Logger.info("Instance: #{rec.instance} (#{idx} of #{:erlang.get(:instance_num)})")
      data = get_instance_data(rec.instance)
      %{instance: rec.instance,
        lower_bound: max(SSP.get_lower_bound(data, opts),
      SSP.get_trivial_lower_bound(data))} end)
  end

  def stats(filter_fun \\ fn x -> x end) do
    {:ok, recs} = CubDB.select(:cubdb)
    recs
    |> filter_fun.()
    |> tap(fn instances -> Logger.debug("Instances: #{inspect length(instances)}") end)
    |> Enum.map(fn {_key, rec} -> rec end)
    |> stats_summary()
  end

  def stats_summary(results) do
    lower_bounds =
      parse_lower_bounds("results/lower_bounds.csv")
      |> Enum.reduce(%{}, fn lb, acc -> Map.put(acc, lb.instance, lb.lower_bound) end)
    results
    |> Enum.group_by(fn rec -> %{J: rec[:J], T: rec[:T]} end)
    |> Enum.map(fn {key, recs} -> %{sizes: key, total: length(recs), records: recs,
      gaps:
      recs
      |> Enum.map(fn rec ->
        rec = Map.put(rec, :lower_bound, Map.get(lower_bounds, rec.instance))
        optimality_gap(rec) end)
      |> Enum.reduce(%{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)
      |> then(fn gaps ->
        List.foldr([0, 1, 2], [], fn g, acc ->
            [Map.get(gaps, g, 0) | acc]
        end)
      end)
      } end)

    |> Enum.sort_by(fn rec ->
      sizes = rec.sizes
      {sizes[:J], sizes[:T], sizes[:C]}
   end)
  end
  def stats_to_latex(stats) do
    stats
    |> Enum.map(fn rec ->
      bigger_gaps = rec.total - Enum.sum(rec.gaps)
      sizes = rec.sizes
      [sizes[:J], sizes[:T], rec.total] ++ rec.gaps ++ [bigger_gaps]
      |> Enum.join(" & ")
      |> then(fn latex_row -> latex_row <> " \\\\" end)
    end)
    |> Enum.join("\n\\hline\n")
    |> then(fn latex -> File.write!("latex_results", latex) end)
  end

  def optimality_gap(instance_data) do
    optimal?(instance_data) && 0
    ||
    (
      lb = Map.get(instance_data, :lower_bound) || 0
      instance_data.objective -
      max(lb, get_trivial_lower_bound(instance_data)
      )
    )
  end
  def yanasse_beam_search_results() do
    obks = [
      %{instance: "L22-3", obks: 18, our: 20, ys: 18.2},
      %{instance: "L22-4", obks: 15, our: 15, ys: 17},
      %{instance: "L22-5", obks: 17, our: 18, ys: 17},
      %{instance: "L22-6", obks: 15, our: 15, ys: 16},
      %{instance: "L22-8", obks: 19, our: 21, ys: 19.6},
      %{instance: "L22-9", obks: 18, our: 18, ys: 18},
      %{instance: "L22-10", obks: 16, our: 16, ys: 17},
      %{instance: "L23-2", obks: 10, our: 10, ys: 10},
      %{instance: "L23-3", obks: 10, our: 10, ys: 11},
      %{instance: "L25-6", obks: 5, our: 5, ys: 6}
    ]

    Enum.map(obks, fn inst ->
      "instances/MTSP/Laporte/Tabela6/#{inst.instance}.txt"
    end)
  end
end
