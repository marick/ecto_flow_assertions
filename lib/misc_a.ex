defmodule FlowAssertions.Ecto.MiscA do
 use FlowAssertions.Define
 use FlowAssertions
 alias FlowAssertions.Ecto.Messages

  # defchain assert_assoc_loaded(struct, keys) when is_list(keys) do
  #   for k <- keys, do: assert_assoc_loaded(struct, k)
  # end

  defchain assert_assoc_loaded(struct, key) when is_struct(struct) do
    struct_must_have_key!(struct, key)

    value = Map.get(struct, key)
    case value do
      %Ecto.Association.NotLoaded{} ->
        elaborate_flunk(Messages.assoc_not_loaded(key), left: value)
      _ ->
        :ok
    end
  end

  # defchain refute_assoc_loaded(struct, keys) when is_list(keys) do
  #   for k <- keys, do: refute_assoc_loaded(struct, k)
  # end

  defchain refute_assoc_loaded(struct, key) do 
    struct_must_have_key!(struct, key)
    value = Map.get(struct, key)
    case value do
      %Ecto.Association.NotLoaded{} ->
        :ok
      _ ->
        elaborate_flunk(Messages.assoc_loaded(key), left: value)
    end
  end
  


  defp assoc_loaded?(struct, key) do
    not match?(%Ecto.Association.NotLoaded{}, Map.get(struct, key))
  end

  # defchain assert_schema(value, module_name) do
  #   assert value.__meta__.schema == module_name
  # end

  # defchain assert_schema_copy(new, original, [ignoring: extras]) do
  #   ignoring = extras ++ [:inserted_at, :updated_at, :__meta__]
  #   assert_same_map(new, original, ignoring: ignoring)
  # end
end
