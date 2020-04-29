defmodule HomeDash.Util.Constants do
  @scenes [HomeDash.Scene.Home, HomeDash.Scene.ElectricityToday, HomeDash.Scene.InverterInfo]
  def scenes(), do: @scenes

  @col_0 {75, 74, 84}
  @col_1 {103, 115, 129}
  @col_2 {130, 160, 170}
  @col_3 {163, 207, 205}

  def col_0(), do: @col_0
  def col_1(), do: @col_1
  def col_2(), do: @col_2
  def col_3(), do: @col_3

  @dark_button_theme %{
    text: @col_3,
    background: {30, 30, 30},
    active: {50, 50, 50},
    border: {20, 20, 20}
  }

  def dark_button_theme(), do: @dark_button_theme
end
