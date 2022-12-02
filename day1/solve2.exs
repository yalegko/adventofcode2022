parse = fn
	line when line === "" -> -1
	line -> elem(Integer.parse(line, 10), 0)
end

collect_max = fn
	el,  [maxes, cur] when el !== -1 -> [max, cur + el]

	# Sorted insertion :|
	_el, [[m1, m2, _m3], cur] when cur >= m1 -> [[cur, m1, m2], 0]
	_el, [[m1, m2, _m3], cur] when cur >= m2 -> [[m1, cur, m2], 0]
	_el, [[m1, m2, m3],  cur] when cur >= m3 -> [[m1, m2, cur], 0]

	_el, [max, _cur] -> [max, 0]
end

[fname] = System.argv()
sum = File.stream!(fname)
	|> Stream.map(&String.trim/1)
	|> Stream.map(parse)
	|> Stream.transform([[0,0,0], 0],collect_max)
	|> Stream.take(-1)
	|> Enum.flat_map(fn([maxes, _]) -> maxes end)
	|> Enum.reduce(fn(el, acc) -> el + acc end)
IO.puts(sum)
