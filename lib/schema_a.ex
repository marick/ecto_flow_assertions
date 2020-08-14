defmodule FlowAssertions.Ecto.SchemaA do
  use FlowAssertions.Define
  use FlowAssertions
  alias FlowAssertions.Ecto.Messages

  @moduledoc """
  Assertions for values defined by the macros in `Ecto.Schema`.
  """

  @doc """
  Assert that an association has been loaded.

      Animal.typical(id, preload: [:service_gaps])
      |> assert_loaded(:service_gaps)

  The second argument can either be a single key or a list of keys.
  """
 
  defchain assert_assoc_loaded(struct, key_or_keys) when is_list(key_or_keys) do
    for k <- key_or_keys, do: assert_assoc_loaded(struct, k)
  end

  defchain assert_assoc_loaded(struct, key_or_keys) when is_struct(struct) do
    struct_must_have_key!(struct, key_or_keys)

    value = Map.get(struct, key_or_keys)
    case value do
      %Ecto.Association.NotLoaded{} ->
        elaborate_flunk(Messages.assoc_not_loaded(key_or_keys), left: value)
      _ ->
        :ok
    end
  end

  @doc """
  Fail when an association has been loaded.

      Animal.typical(id, preload: [:species])
      |> refute_loaded(:service_gaps)

  The second argument can either be a single key or a list of keys.
  """
  defchain refute_assoc_loaded(struct, key_or_keys) when is_list(key_or_keys) do
    for k <- key_or_keys, do: refute_assoc_loaded(struct, k)
  end

  defchain refute_assoc_loaded(struct, key_or_keys) do 
    struct_must_have_key!(struct, key_or_keys)
    value = Map.get(struct, key_or_keys)
    case value do
      %Ecto.Association.NotLoaded{} ->
        :ok
      _ ->
        elaborate_flunk(Messages.assoc_loaded(key_or_keys), left: value)
    end
  end

  @doc """
  Check that the given value matches a schema's name.
  
  We consider a schema's name to be that found inside its
  `Ecto.Schema.Metadata`, which is - by default - the module
  it was defined in. Embedded schemas don't have metadata, so
  `FlowAssertions.StructA.assert_struct_named/2` is the appropriate
  assertion for them.
  """
  defchain assert_schema_name(value, name) when is_struct(value) do
    if Map.has_key?(value, :__meta__) do 
      elaborate_assert_equal(value.__meta__.schema, name)
    else
      elaborate_flunk(Messages.maybe_embedded, left: value)
    end
  end

  def assert_schema_name(value, _module_name) do
    elaborate_flunk(Messages.never_a_schema, left: value)
  end

  # defchain assert_schema_copy(new, original, [ignoring: extras]) do
  #   ignoring = extras ++ [:inserted_at, :updated_at, :__meta__]
  #   assert_same_map(new, original, ignoring: ignoring)
  # end
end
