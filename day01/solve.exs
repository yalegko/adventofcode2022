parse = fn
	line when line === "" -> -1
	line -> elem(Integer.parse(line, 10), 0)
end

collect_max = fn
	el, [max, cur] when el !== -1 -> [max, cur + el]
	_el, [max, cur] when cur > max -> [cur, 0]
	_el, [max, _cur] -> [max, 0]
end

[fname] = System.argv()
File.stream!(fname)
	|> Stream.map(&String.trim/1)
	|> Stream.map(parse)
	|> Stream.scan([0, 0],collect_max)
	|> Stream.take(-1)
	|> Stream.map(&IO.inspect/1)
	|> Stream.run()
