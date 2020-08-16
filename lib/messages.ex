defmodule FlowAssertions.Ecto.Messages do

  @moduledoc false

  def assoc_not_loaded(key), do: "Field `#{inspect key}` is not loaded."
  def assoc_loaded(key), do: "Field `#{inspect key}` was incorrectly loaded."

  def stock_equality, do: "Assertion with == failed"

  def maybe_embedded,
    do: "The value doesn't have a metadata field. Is it an embedded_schema?"

  def never_a_schema, do: "The value looks nothing like an Ecto schema"

  def changeset_invalid, do: "The changeset is invalid"
  def changeset_valid, do: "The changeset is supposed to be invalid"

  def some_field_changes(changeset) do 
    changed_fields = Map.keys(changeset.changes)
    "No fields were supposed to change, but these did: #{inspect changed_fields}"
  end

  def bad_field_change(field),
    do: "Field `#{inspect field}` should not have changed, but it did"
    
  def no_error_for_field(field), do: "There are no errors for field `#{inspect field}`"
  def not_right_error_message(field),
    do: "Field #{inspect field} does not have a matching error message."

  def unexpected_error(field), do: "Field #{inspect field} unexpectedly has an error"
end
