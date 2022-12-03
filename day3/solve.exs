
[fname] = System.argv()
File.stream!(fname)
  |> Stream.map(&String.trim/1)

  # Split in 2 halves.
  |> Stream.map(fn line ->
    mid = div(String.length(line), 2)
    String.split_at(line, mid)
  end)

  # Find the matching character: half2 is interpreted as regex set and we are
  # looking for the any matching character (as we are guaranted to have the only one).
  |> Stream.map(fn {half1, half2} = _splitted ->
    [matched] = Regex.compile!("[#{half2}]")
      |> Regex.run(half1)
    [letter] = String.to_charlist(matched)
    letter
  end)

  # Weight the results
  |> Stream.map(fn
    l when l >= ?a and l <= ?z -> l - ?a + 1
    l when l >= ?A and l <= ?Z -> l - ?A + 27
  end)

  # Sum everything.
  |> Stream.scan(&(&1 + &2))
  |> Stream.take(-1)
  |> Stream.each(&IO.puts/1)
  |> Stream.run()
