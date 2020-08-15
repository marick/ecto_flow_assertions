defmodule FlowAssertions.Ecto.ChangesetA do
  use FlowAssertions.Define
  alias FlowAssertions.Ecto.Messages
  use FlowAssertions
  alias Ecto.Changeset
  

  @moduledoc """
  Assertions for `Ecto.Changeset` structures.
  """ 
  
  # ------------------------------------------------------------------------

  @doc """
  A pipeline-ready version of `assert changeset.valid?`
  """
  defchain assert_valid(%Changeset{} = changeset) do 
    elaborate_assert(changeset.valid?, Messages.changeset_invalid,
      expr: AssertionError.no_value,
      left: changeset)
  end

  @doc """
  A pipeline-ready version of `refute changeset.valid?`
  """
  defchain assert_invalid(%Changeset{} = changeset) do
    elaborate_assert(not changeset.valid?, Messages.changeset_valid,
      expr: AssertionError.no_value,
      left: changeset)
  end

  # ------------------------------------------------------------------------
  @doc ~S"""
  Applies `FlowAssertions.MapA.assert_fields/2` to the changes in the changeset.

  To check that fields have been changed:

      changeset |> assert_changes([:name, :tags])

  To check specific changed values:

      changeset |> assert_changes(name: "Bossie", tags: [])

  """
  defchain assert_changes(%Changeset{} = changeset, keyword_list),
    do: assert_fields(changeset.changes, keyword_list)

  @doc """
  Like `assert_changes/2` for cases where you care only about a single field.

  This is just a convenience function for the grammatically obsessive.

      changeset |> assert_change(:name)
      changeset |> assert_change(name: "Bossie")
  """
  def assert_change(cs, field_description) when not is_list(field_description),
    do: assert_changes(cs, [field_description])
  def assert_change(cs, field_description),
    do: assert_changes(cs, field_description)

  @doc """
  The changeset must contain no changes.
  """
  
  defchain assert_no_changes(%Changeset{} = changeset) do
    changes = changeset.changes
    elaborate_assert(changes == %{}, Messages.some_field_changes(changeset),
      left: changeset)
  end

  # @doc """
  # Require that particular fields have no changes. Unmentioned fields may
  # have changes. When there's only a single field, it needn't be enclosed in
  # a list.

  #     assert_unchanged(changeset, :name)
  #     assert_unchanged(changeset, [:name, :tags])
  # """
  # defchain assert_unchanged(%Changeset{} = changeset, field) when is_atom(field) do
  #   struct_must_have_key!(changeset.data, field)
  #   refute Map.has_key?(changeset.changes, field),
  #     "Field `#{inspect field}` has changed"
  # end

  # defchain assert_unchanged(%Changeset{} = changeset, fields) when is_list(fields),
  #   do: Enum.map fields, &(assert_unchanged changeset, &1)


  # # ------------------------------------------------------------------------
  # @doc """
  # Assert that a changeset contains specific errors. In the simplest case,
  # it requires that the fields have at least one error, but doesn't require
  # any specific message:

  #     assert_errors(changeset, [:name, :tags])
  
  # A message may also be required:

  #     assert_errors(changeset,
  #       name: "may not be blank",
  #       tags: "is invalid")

  # The given string must be an exact match for one of the field's errors.
  # (It is not a failure for others to be unmentioned.)

  # If you want to list more than one message, enclose them in a list:

  #     assert_errors(changeset,
  #       name: "may not be blank",
  #       tags: ["is invalid",
  #              "has something else wrong"])

  # The list need not be a complete list of errors.
  # """
  # defchain assert_errors(%Changeset{} = changeset, list) do
  #   errors = errors_on(changeset)

  #   any_error_check = fn field ->
  #     assert Map.has_key?(errors, field),
  #       "There are no errors for field `#{inspect field}`"
  #   end

  #   message_check = fn field, expected ->
  #     any_error_check.(field)

  #     msg = """
  #     `#{inspect field}` is missing an error message.
  #     expected: #{inspect expected}
  #     actual:   #{inspect errors[field]}
  #     """
      
  #     assert expected in errors[field], msg
  #   end
    
  #   Enum.map(list, fn
  #     field when is_atom(field) ->
  #       assert any_error_check.(field)
  #     {field, expected} when is_binary(expected) ->
  #       message_check.(field, expected)
  #     {field, expecteds} when is_list(expecteds) ->
  #       Enum.map expecteds, &(message_check.(field, &1))
  #   end)
  # end

  # @doc """
  # Like `assert_error` but reads better when there's only a single error
  # to be checked:

  #     assert_error(changeset, name: "is invalid")

  # If the message isn't to be checked, you can use a single atom:

  #     assert_error(changeset, :name)
  # """
  
  # defchain assert_error(cs, arg2) when is_atom(arg2), do: assert_errors(cs, [arg2])
  # defchain assert_error(cs, arg2),                    do: assert_errors(cs,  arg2)

  # @doc """
  # Require that none of the named fields have an associated error:

  #     assert_error_free(changes, [:in_service_datestring, :name])
  
  # There can also be a singleton field:

  #     assert_error_free(changes, :in_service_datestring)
  # """

  # defchain assert_error_free(changeset, field) when is_atom(field),
  #   do: assert_error_free(changeset, [field])
  # defchain assert_error_free(changeset, fields) do
  #   errors = errors_on(changeset)

  #   check = fn(field) ->
  #     struct_must_have_key!(changeset.data, field)
  #     refute Map.has_key?(errors, field),
  #       "There is an error for field `#{inspect field}`"
  #   end
      
  #   Enum.map(fields, check)
  # end

  # # ------------------------------------------------------------------------

  # defchain assert_data(changeset, keylist) when is_list(keylist) do
  #   assert_fields(changeset.data, keylist)
  # end
  
  # defchain assert_data(changeset, expected) do
  #   assert changeset.data == expected
  # end

  # @doc """
  # Assert that a field in the data part of the changeset matches a binding form

  #     assert_data_shape(changeset, :field, %User{})
  #     assert_data_shape(changeset, :field, [_ | _])
  # """
  # defmacro assert_data_shape(changeset, key, shape) do
  #   quote do
  #     eval_once = unquote(changeset)
  #     assert_field_shape(eval_once.data, unquote(key), unquote(shape))
  #     eval_once
  #   end
  # end

  # # ----------------------------------------------------------------------------

  # @doc """

  # Assert that the changeset will cause `error_tag` and friends to show
  # errors. This happens automatically when the changeset comes from an
  # Ecto function, but that doesn't happen with view models.
  # """
  # defchain assert_form_will_display_errors(changeset),
  #   do: assert changeset.action != nil

  # defchain refute_form_will_display_errors(changeset),
  #   do: assert changeset.action == nil



  # def with_singleton(%Changeset{} = changeset, fetch_how, field) do
  #   apply(ChangesetX, fetch_how, [changeset, field])
  #   |> singleton_content
  # end
end
