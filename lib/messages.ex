defmodule FlowAssertions.Ecto.Messages do

  def assoc_not_loaded(key), do: "Field `#{inspect key}` is not loaded."
  def assoc_loaded(key), do: "Field `#{inspect key}` was incorrectly loaded."

  def stock_equality, do: "Assertion with == failed"

  def maybe_embedded,
    do: "The value doesn't have a metadata field. Is it an embedded_schema?"

  def never_a_schema, do: "The value looks nothing like an Ecto schema"
end
