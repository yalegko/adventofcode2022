
collect_max = fn
	# Still counting a group.
	el,  [maxes, cur] when el !== -1 -> [maxes, cur + el]

	# Sorted insertion :|
	_el, [[m1, m2, _m3], cur] when cur >= m1 -> [[cur, m1, m2], 0]
	_el, [[m1, m2, _m3], cur] when cur >= m2 -> [[m1, cur, m2], 0]
	_el, [[m1, m2, m3],  cur] when cur >= m3 -> [[m1, m2, cur], 0]

	# `cur` is smaller than all `maxes`.
	_el, [maxes, _cur] -> [maxes, 0]
end

[fname] = System.argv()
sum = File.stream!(fname)
	|> Stream.map(&String.trim/1)
	|> Stream.map(fn
		""   -> -1 # New group.
		line -> elem(Integer.parse(line, 10), 0)
	end)
	|> Stream.scan([[0,0,0], 0],collect_max)
	|> Stream.take(-1)
	|> Enum.flat_map(fn([maxes, _]) -> maxes end)
	|> Enum.reduce(fn(el, acc) -> el + acc end)
IO.puts(sum)
