[fname] = System.argv()

File.stream!(fname)
|> Stream.map(&String.trim/1)

# a1-b1,a2-b2 -> [a1, b1, a2, b2].
|> Stream.map(fn line ->
  line
  |> String.split(",")
  |> Enum.flat_map(&String.split(&1, "-"))
  |> Enum.map(&String.to_integer/1)
end)

# Count overlapped intervals.
|> Stream.scan(0, fn [a1, b1, a2, b2], acc ->
  # (a1 <= a2 <= b1 <= b2) or (a2 <= a1 <= b2 <= b1)
  if (a2 <= b1 and b1 <= b2) or (a1 <= b2 and b2 <= b1) do
    acc + 1
  else
    acc
  end
end)

|> Stream.take(-1)
|> Stream.each(&IO.inspect/1)
|> Stream.run()
