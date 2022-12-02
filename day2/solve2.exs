defmodule Game do
  def decrypt_figure("A"), do: :rock
  def decrypt_figure("B"), do: :papper
  def decrypt_figure("C"), do: :scissors

  def decrypt_result("X"), do: :lose
  def decrypt_result("Y"), do: :draw
  def decrypt_result("Z"), do: :win

  def figure_score(:rock), do: 1
  def figure_score(:papper), do: 2
  def figure_score(:scissors), do: 3

  def game_score(:win), do: 6
  def game_score(:draw), do: 3
  def game_score(:lose), do: 0

  def find_move(they, outcome) do
    [:rock, :papper, :scissors]
      |> Enum.find(&(outcome == round_outcome(they, &1)))
  end

  # Reuse.
  defp round_outcome(they, us) do
    case {they, us} do
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
  end
end


[fname] = System.argv()
sum = File.stream!(fname)
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.split(&1, " "))
  |> Stream.map(fn [they, result] ->
    [
      Game.decrypt_figure(they),
      Game.decrypt_result(result)
    ]
  end)
  |> Stream.map(fn [they, result] ->
    Game.game_score(result) + Game.figure_score(Game.find_move(they, result))
  end)
  |> Enum.reduce(&(&1+&2))
IO.puts(sum)
