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

  
  @doc """
  Require a changeset to have no changes in particular fields. Unmentioned fields may
  have changes. When there's only a single field, it needn't be enclosed in a list.

      changeset |> assert_no_changes([:name, :tags])
      changeset |> assert_no_changes(:name)
  """
  defchain assert_no_changes(%Changeset{} = changeset, field) when is_atom(field) do
    struct_must_have_key!(changeset.data, field)
    elaborate_refute(Map.has_key?(changeset.changes, field),
      Messages.bad_field_change(field),
      left: changeset)
  end

  defchain assert_no_changes(%Changeset{} = changeset, field_or_fields)
  when is_list(field_or_fields),
    do: Enum.map field_or_fields, &(assert_no_changes changeset, &1)


  # ------------------------------------------------------------------------
  @doc ~S"""
  Assert that a changeset contains specific errors. In the simplest case,
  it requires that each named field have at least one error, but doesn't require
  any specific message:

      changeset |> assert_errors([:name, :tags])
  
  A message may also be required:

      changeset
      |> assert_errors(name: "may not be blank", tags: "is invalid")

  The given string must be an exact match for one of the field's error messages.

  If you want to check more than one error message for a given field,
  enclose them in a list:

      changeset
      |> assert_errors(name: "may not be blank",
                       tags: ["is invalid", "has something else wrong"])

  The list need not be a complete list of errors.
  """
  defchain assert_errors(%Changeset{} = changeset, error_descriptions) do
    errors_map = phoenix_errors_on(changeset)

    assert_field_has_an_error = fn field ->
      elaborate_assert(Map.has_key?(errors_map, field),
        Messages.no_error_for_field(field),
        left: changeset)
    end

    has_message_match? = fn expected, field_error_list ->
      Enum.any?(field_error_list, fn error_message ->
        good_enough?(error_message, expected)
      end)
    end

    assert_message_match = fn field, expected ->
      field_error_list = errors_map[field]
      
      elaborate_assert(has_message_match?.(expected, field_error_list),
        Messages.not_right_error_message(field),
        left: field_error_list,
        right: expected)
    end

    Enum.map(error_descriptions, fn
      field                when is_atom(field)     ->
        assert_field_has_an_error.(field)
      
      {field, expecteds}   when is_list(expecteds) ->
        assert_field_has_an_error.(field)
        for expected <- expecteds,
          do: assert_message_match.(field, expected)

      {field, expected}                            ->
        assert_field_has_an_error.(field)
        assert_message_match.(field, expected)
    end)
  end

  @doc """
  Like `assert_errors` but reads better when there's only a single error
  to be checked:

      assert_error(changeset, name: "is invalid")

  If the message isn't to be checked, you can use a single atom:

      assert_error(changeset, :name)
  """
  
  defchain assert_error(cs, error_description) when is_atom(error_description),
    do: assert_errors(cs, [error_description])
  defchain assert_error(cs, error_description),
    do: assert_errors(cs,  error_description)

  @doc """
  Assert that a field or fields have no associated errors.

      changeset |> assert_error_free([:in_service_datestring, :name])
  
  You needn't use a list if there's only one field to check. 

      changeset |> assert_error_free(:in_service_datestring)
  """

  defchain assert_error_free(changeset, field) when is_atom(field),
    do: assert_error_free(changeset, [field])
  defchain assert_error_free(changeset, fields) do
    errors = phoenix_errors_on(changeset)

    check = fn(field) ->
      struct_must_have_key!(changeset.data, field)
      elaborate_refute(Map.has_key?(errors, field),
        Messages.unexpected_error(field),
        left: changeset)
    end
      
    Enum.map(fields, check)
  end

  # # ------------------------------------------------------------------------

  defchain assert_data(changeset, expected) do
    assert_fields(changeset.data, expected)
  end

  @doc """
  Assert that a field in the data part of the changeset matches a binding form

      changeset |> assert_data_shape(:field, %User{})
      changeset |> assert_data_shape(:field, [_ | _])
  """
  defmacro assert_data_shape(changeset, key, shape) do
    quote do
      eval_once = unquote(changeset)
      assert_field_shape(eval_once.data, unquote(key), unquote(shape))
      eval_once
    end
  end

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

  # ----------------------------------------------------------------------------

  # Taken from Phoenix's `test/support/data_case.ex`.
  defp phoenix_errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

end
