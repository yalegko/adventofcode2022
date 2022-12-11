
# Returns %{a: 1, b: 1, ...} for all chars existed in the line (not counting them).
get_unique_chars_map = fn line ->
  line
    |> Enum.reduce(%{}, fn char, map -> Map.put(map, char, 1) end)
end

# Sum the values of duplicated keys.
sum_maps = fn m1, m2 ->
  Map.merge(m1, m2, fn _key, v1, v2 -> v1 + v2 end)
end

[fname] = System.argv()
File.stream!(fname)
  |> Stream.map(&String.trim/1)
  |> Stream.chunk_every(3)

  # Find the symbol used in every of all 3 lines.
  |> Stream.map(fn chunk ->
    chunk
      |> Enum.map(&String.graphemes/1)
      |> Enum.map(get_unique_chars_map)
      |> Enum.reduce(%{}, sum_maps)
      |> Enum.find(fn {_k, v} -> v == 3 end)
      |> elem(0) # Result is tuple {k,v}.
      |> String.to_charlist()
      |> Enum.fetch!(0)
  end)

  # Weight the result.
  |> Stream.map(fn
    l when l >= ?a and l <= ?z -> l - ?a + 1
    l when l >= ?A and l <= ?Z -> l - ?A + 27
  end)

  # Sum everything.
  |> Stream.scan(&(&1 + &2))
  |> Stream.take(-1)
  |> Stream.each(&IO.inspect/1)
  |> Stream.run()
