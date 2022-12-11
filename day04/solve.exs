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

# Count intervals cotained one in another.
|> Stream.scan(0, fn [a1, b1, a2, b2], acc ->
  if (a1 <= a2 and b2 <= b1) or (a2 <= a1 and b1 <= b2) do
    acc + 1
  else
    acc
  end
end)

|> Stream.take(-1)
|> Stream.each(&IO.inspect/1)
|> Stream.run()
