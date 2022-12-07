#!/usr/bin/env elixir

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

  def enum_children(tree), do: Map.values(tree.children)
end

defmodule FS do
  defstruct path_stack: [], file_tree: Tree.new("/")

  def cd(fs, "/"), do: %FS{fs | path_stack: []}
  def cd(fs, ".."), do: %FS{fs | path_stack: tl(fs.path_stack)}
  def cd(fs, dir), do: %FS{fs | path_stack: [dir | fs.path_stack]}

  # Observes a file of the given size, adding it to the FS tree.
  def ls(fs, file_name, size) do
    file_path = Enum.reverse([file_name | fs.path_stack])
    %FS{fs | file_tree: Tree.add(fs.file_tree, file_path, size)}
  end

  # Returns map %{ dir_path: cumulative_dir_size }.
  def dir_sizes(fs) do
    {_, sizes_map} = calc_size(fs.file_tree, %{}, [])
    sizes_map
  end

  # Recursively counts current node (directory) size, updating a `sizes_map` with the
  # total size of the processing directory.
  defp calc_size(%Tree{value: :dir} = tree, sizes_map, path) do
    {node_size, sizes_map} =
      tree
      |> Tree.enum_children()
      |> Enum.reduce(
        {0, sizes_map},
        fn child, {sum, sizes_map} ->
          {child_size, updated_map} = calc_size(child, sizes_map, [child.name | path])
          {sum + child_size, updated_map}
        end
      )

    node_path = "/" <> (path |> Enum.reverse() |> Enum.join("/"))
    {node_size, Map.put(sizes_map, node_path, node_size)}
  end

  # For files it just returns the file size itself without any traverse.
  defp calc_size(%Tree{value: size}, sizes_map, _path) do
    {size, sizes_map}
  end
end

[fname] = System.argv()

sizes =
  File.stream!(fname)
  |> Stream.map(&String.split/1)

  # Process the given commands to form the directory tree.
  |> Stream.scan(struct(FS), fn
    ["$", "cd", dir], fs -> FS.cd(fs, dir)
    ["$", "ls"], fs -> fs
    ["dir", _dirname], fs -> fs
    [size, fname], fs -> FS.ls(fs, fname, String.to_integer(size))
  end)

  # Translate the tree in to a list of pairs {directory, size}.
  |> Stream.take(-1)
  |> Enum.to_list()
  |> hd
  # |> IO.inspect(label: "Final FS")
  |> FS.dir_sizes()

IO.inspect(sizes["/"], label: "Total used space")

free_space = 70_000_000 - sizes["/"]
needed_space = 30_000_000 - free_space
IO.inspect(needed_space, label: "Need to free")

# Now find the first directory larger than needed size.
sizes
|> Enum.sort(fn {_name1, size1}, {_name2, size2} -> size1 <= size2 end)
|> Enum.find(:not_found, fn {_dir, size} -> size >= needed_space end)
|> (fn {dir, size} -> IO.puts("You need to drop dir '#{dir}' of size #{size}") end).()
