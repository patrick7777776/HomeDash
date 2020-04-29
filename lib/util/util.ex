defmodule HomeDash.Util do
  # find left, right neighbour of an element in a list
  # nil if list is empty or element not member of list
  def neighbours([], _), do: nil
  def neighbours([first | _] = list, element), do: n(list, element, first)

  defp n([element], element, _), do: {element, element}
  defp n([left, element, right | _], element, _), do: {left, right}
  defp n([left, element], element, first), do: {left, first}
  defp n([element, right | rest], element, _), do: {last([right | rest]), right}
  defp n([_ | es], element, first), do: n(es, element, first)
  defp n(_, _, _), do: nil

  defp last([e]), do: e
  defp last([_ | rest]), do: last(rest)
end
