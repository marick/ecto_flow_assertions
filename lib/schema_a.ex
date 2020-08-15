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

  @doc """
  Map comparison that auto-ignores fields typically irrelevant when working with schemas. 

  Works just like `FlowAssertions.MapA.assert_same_map/3`, except that
  it ignores the `:updated_at`, `:created_at`, and `:__meta__` fields
  (if present).
  
      old
      |> VM.Animal.change(name: "bossie")
      |> assert_same_schema(old, except: [name: "bossie"]

  You can compare one or more of those three fields by using the `comparing:` or
  `except:` options:

      assert_same_schema(new, old, except: newer_than(old)

  """
  defchain assert_same_schema(new, old, opts \\ []) do
    default_ignore = those_in(new, [:inserted_at, :updated_at, :__meta__])
    ignore = Keyword.get(opts, :ignoring, []) ++ default_ignore
    except = Keyword.get(opts, :except, [])

    if Keyword.has_key?(opts, :comparing) do
      assert_same_map(new, old, opts)
    else
      assert_same_map(new, old, ignoring: ignore, except: except)
    end
  end

  defp those_in(struct, keys), do: Enum.filter(keys, &(Map.has_key?(struct, &1)))
end
