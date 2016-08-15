defmodule ExTika.Utils do
  @moduledoc """
  A collection of handy helper functions.
  """

  @doc """
  Returns a string where leading/trailing Unicode whitespace has been removed.
  Works on versions of Elixir before 1.3 which don't have the String.trim
  function.

  ## Examples

      iex> ExTika.Utils.strip("   abc   ")
      "abc"
  """
  @spec trim(String.t) :: String.t
  def trim(s) do
    if :erlang.function_exported(String, :trim, 1) do
      String.trim(s)
    else
      String.strip(s)
    end
  end
end
