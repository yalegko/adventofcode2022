#!/usr/bin/env elixir

defmodule FS do
  defstruct path_stack: [], files: %{}

  def cd(fs, "/") do
    %FS{fs | path_stack: []}
  end

  def cd(fs, "..") do
    [_ | rest] = fs.path_stack
    %FS{fs | path_stack: rest}
  end

  def cd(fs, dir) do
    %FS{fs | path_stack: [dir | fs.path_stack]}
  end

  def ls(fs, file_name, size) do
    %FS{fs | files: Map.put(fs.files, abs(fs, file_name), size)}
  end

  defp abs(fs, file_name) do
    path =
      fs.path_stack
      |> Enum.reverse()
      |> Enum.concat([file_name])
      |> Enum.join("/")

    "/" <> path
  end
end

defmodule Tree do
  defstruct name: "/", value: :dir, children: %{}

  def new(name), do: %Tree{name: name, value: :dir, children: %{}}
  def new(name, size), do: %Tree{name: name, value: size, children: %{}}

  def add(tree, [file_name], size) do
    %Tree{tree | children: Map.put(tree.children, file_name, new(file_name, size))}
  end

  def add(tree, [node | rest] = _path, value) do
    children = Map.put_new(tree.children, node, new(node))
    %Tree{tree | children: Map.put(children, node, add(children[node], rest, value))}
  end

  def dir_sizes(tree) do
    {_, sizes} = calc_size(tree, %{}, "")
    sizes
  end

  def calc_size(%Tree{value: :dir} = tree, sizes, path) do
    {sum, sizes} =
      tree.children
      |> Map.values()
      |> Enum.reduce(
        {0, sizes},
        fn child, {sum, sizes} ->
          {child_sum, sizes} = calc_size(child, sizes, path <> "/" <> child.name)
          {sum + child_sum, sizes}
        end
      )

    {sum, Map.put(sizes, path, sum)}
  end

  def calc_size(%Tree{value: size}, sizes, path) do
    {size, sizes}
  end
end

[fname] = System.argv()

File.stream!(fname)
|> Stream.map(&String.split/1)
|> Stream.scan(struct(FS), fn
  ["$", "cd", dir], fs -> FS.cd(fs, dir)
  ["$", "ls"], fs -> fs
  ["dir", _dirname], fs -> fs
  [size, fname], fs -> FS.ls(fs, fname, String.to_integer(size))
end)
|> Stream.take(-1)
|> Stream.each(fn fs ->
  IO.inspect(fs)

  fs.files
  |> Enum.reduce(Tree.new("/"), fn {file, size}, tree ->
    [_ | path] = String.split(file, "/")
    Tree.add(tree, path, size)
  end)
  |> IO.inspect()
  |> Tree.dir_sizes()
  |> IO.inspect()
  |> Enum.filter(fn {_dir, size} -> size <= 100_000 end)
  |> IO.inspect()
  |> Enum.reduce(0, fn {_dir, size}, acc -> size + acc end)
  |> IO.inspect(label: "Total")
end)
|> Stream.run()
