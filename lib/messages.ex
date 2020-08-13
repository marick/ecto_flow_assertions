defmodule FlowAssertions.Ecto.Messages do

  def assoc_not_loaded(key), do: "Field `#{inspect key}` is not loaded."
  def assoc_loaded(key), do: "Field `#{inspect key}` was incorrectly loaded."
end
