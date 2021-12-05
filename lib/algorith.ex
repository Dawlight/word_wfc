defmodule WordWFC.Algorithm do
  def generate_index(min_overlap \\ 1, pattern_size \\ 2) when pattern_size > min_overlap do
    words =
      File.read!("lib/input")
      |> String.split(["\n", " "], trim: true)

    patterns =
      words
      |> Enum.chunk_every(pattern_size, 1, :discard)

    unique_patterns = patterns |> Enum.uniq()

    pattern_lookup =
      for {pattern, index} <- unique_patterns |> Enum.with_index(),
          into: %{},
          do: {index, pattern}

    index_lookup = for {key, value} <- pattern_lookup, into: %{}, do: {value, key}

    all_indexes = pattern_lookup |> Map.keys()

    frequencies =
      patterns
      |> Enum.frequencies()
      |> Enum.to_list()
      |> Enum.map(fn {pattern, frequency} -> {index_lookup[pattern], frequency} end)
      |> Map.new()

    Task.async_stream(pattern_lookup, fn entry ->
      generate_index_entry(entry, pattern_lookup, min_overlap)
    end)
    |> Enum.reduce([], fn {:ok, result}, list -> [result | list] end)

    frequencies[0] |> IO.inspect(label: "LOL")

    list = for index <- 0..4, do: {index, all_indexes}

    observe(list, frequencies)
  end

  @spec generate_index_entry({any, any}, any, any) :: {any, any}
  defp generate_index_entry({pattern_index, pattern}, pattern_lookup, min_overlap) do
    entry =
      for {op_index, other_pattern} <- pattern_lookup, reduce: %{} do
        index_entry ->
          overlaps = get_overlaps(pattern, other_pattern, min_overlap)

          for {direction, size} <- overlaps, reduce: index_entry do
            index_entry ->
              overlap = {size, op_index}

              index_entry
              |> Map.update(direction, [overlap], fn thing -> [overlap | thing] end)
          end
      end

    {pattern_index, entry}
  end

  defp get_overlaps(pattern_1, pattern_2, min_overlap) do
    overlap_range = min_overlap..(length(pattern_1) - 1)
    overlap_types = [{:right, [pattern_1, pattern_2]}, {:left, [pattern_2, pattern_1]}]

    for {direction, patterns} <- overlap_types, overlap_size <- overlap_range do
      [pattern_a, pattern_b] = patterns
      overlap_a = Enum.slice(pattern_a, -overlap_size, overlap_size)
      overlap_b = Enum.slice(pattern_b, 0, overlap_size)

      case overlap_a == overlap_b do
        true -> {direction, overlap_size}
        false -> nil
      end
    end
    |> List.flatten()
    |> Enum.filter(&(!is_nil(&1)))
  end

  #
  # Observe
  #

  def run_algorithm(length, available_patterns) do
  end

  def observe(list, frequencies) do
    case find_lowest_entropy(list, frequencies) do
      {index, available_words} ->
        nil

      # TODO: SELECTED WEIGHTED RANDOM
      :finished ->
        IO.puts("NICE")
    end
  end

  def find_lowest_entropy(list, frequencies) do
    list
    |> Enum.filter(fn item -> get_list_item_entropy(item, frequencies) > 0 end)
    |> IO.inspect(label: "BIGGER THAN ZERO")
    |> Enum.min_by(fn item -> get_list_item_entropy(item, frequencies) end, fn -> :finished end)
  end

  def get_list_item_entropy({index, available_pattern_indexes}, frequencies) do
    case available_pattern_indexes do
      [_last_item] ->
        0

      available_pattern_indexes when length(available_pattern_indexes) > 1 ->
        total_weight =
          available_pattern_indexes
          |> Enum.map(fn patern_index -> frequencies[patern_index] end)
          |> Enum.sum()
          |> IO.inspect(label: "TOTAL WEIGHT")

        weight_log_sum =
          available_pattern_indexes
          |> Enum.map(fn patern_index ->
            weight = frequencies[patern_index]

            weight * :math.log2(weight)
          end)
          |> Enum.sum()
          |> IO.inspect(label: "WEIGHT LOG")

        :math.log2(total_weight) - weight_log_sum / total_weight + (:rand.uniform() - 0.5) / 10
    end
  end
end
