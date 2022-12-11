defmodule Game do
  def decrypt(move, :they), do:  decode(move, ["A", "B", "C"])
  def decrypt(move, :us),   do:  decode(move, ["X", "Y", "Z"])

  defp decode(move, [rock, papper, scissors] = _code) do
    cond do
      move == rock -> :rock
      move == papper -> :papper
      move == scissors -> :scissors
    end
  end

  def figure_score(:rock), do: 1
  def figure_score(:papper), do: 2
  def figure_score(:scissors), do: 3

  def round_score(they, us) do
    outcome = case {they, us} do
      {:rock, :rock}          -> :draw
      {:rock, :papper}        -> :win
      {:rock, :scissors}      -> :lose

      {:papper, :rock}        -> :lose
      {:papper, :papper}      -> :draw
      {:papper, :scissors}    -> :win

      {:scissors, :rock}      -> :win
      {:scissors, :papper}    -> :lose
      {:scissors, :scissors}  -> :draw
    end

    case outcome do
      :win  -> 6
      :draw -> 3
      :lose -> 0
    end
  end
end


[fname] = System.argv()
sum = File.stream!(fname)
	|> Stream.map(&String.trim/1)
  |> Stream.map(&String.split(&1, " "))
  |> Stream.map(fn [they, us] ->
    [
      Game.decrypt(they, :they),
      Game.decrypt(us, :us)
    ]
  end)
  |> Stream.map(fn [they, us] ->
    Game.round_score(they, us) + Game.figure_score(us)
  end)
  |> Enum.reduce(&(&1+&2))
IO.puts(sum)
