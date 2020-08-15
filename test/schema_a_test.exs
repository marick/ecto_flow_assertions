defmodule FlowAssertions.Ecto.SchemaATest do
  use FlowAssertions.Ecto.Case
  alias FlowAssertions.Messages, as: BaseMessages

  defmodule Tag do 
    use Ecto.Schema
    embedded_schema do
      field :name, :string
    end
  end

  defmodule Animal do
    use Ecto.Schema
    schema "animals" do
      field :name, :string
      has_many :tags, Tag
      timestamps()
    end
  end

  describe "associations" do
    test "assoc_loaded (single key version)" do
      assert assert_assoc_loaded(%Animal{}, :name) == %Animal{}
      assert refute_assoc_loaded(%Animal{}, :tags) == %Animal{}

      assertion_fails(Messages.assoc_not_loaded(:tags),
        fn -> 
          assert_assoc_loaded(%Animal{}, :tags)
        end)


      assertion_fails(Messages.assoc_loaded(:name),
        [left: "fred"],
        fn -> 
          refute_assoc_loaded(%Animal{name: "fred"}, :name)
        end)
    end


    test "multi-key" do
      assertion_fails(Messages.assoc_not_loaded(:tags),
        fn -> 
          assert_assoc_loaded(%Animal{}, [:name, :tags])
        end)


      assertion_fails(Messages.assoc_loaded(:name),
        [left: "fred"],
        fn -> 
          refute_assoc_loaded(%Animal{name: "fred"}, [:name, :tags])
        end)
    end
  end

  describe "assert_schema_name" do
    test "success" do
      assert assert_schema_name(%Animal{}, Animal) == %Animal{}

      assertion_fails(BaseMessages.stock_equality,
        [left: Animal, right: Tag],
        fn -> 
          assert_schema_name(%Animal{}, Tag)
        end)
    end

    test "embedded schemas don't have a meta" do
      assertion_fails(Messages.maybe_embedded,
        [left: %Tag{}],
        fn ->
          assert_schema_name(%Tag{}, Animal)
        end)
    end

    test "none-structs aren't even close to being right" do
      assertion_fails(Messages.never_a_schema,
        [left: %{}],
        fn ->
          assert_schema_name(%{}, Animal)
        end)
    end
  end

  describe "assert_same_schema" do
    defp dirty_ignored_fields(old),
      do: %{ old | inserted_at: "ignore", updated_at: "ignore", __meta__: "ignore"}

    # `assert_same_schema` produces error output like this:
    #    code:  assert_same_schema(new, old, except: [tags: &Enum.empty?/1])
    #    left:  %FlowAssertions.Ecto.SchemaATest.Animal{id: 5, name: "changed"}
    #    right: %FlowAssertions.Ecto.SchemaATest.Animal{id: 5, name: "original"}
    #
    # Notice that it doesn't show a number of the fields in a true `Animal` struct.
    # 
    # That's because `Map.drop` and `Map.take` retain the `__struct__`
    # field.  I don't know if that makes the output better or worse,
    # but I don't think it's worth worrying about.  The tests document
    # what happens naturally.
    
    defp pruned_animal(fields) do
      Enum.into(fields, %{})
      |> Map.put(:__struct__, Animal)
    end
    
    test "certain fields are ignored" do
      old = %Animal{}
      new = dirty_ignored_fields(old)
      assert assert_same_schema(new, old) == new
    end

    test "can be combined with `:except` and `:ignored`" do
      old = %Animal{id: 5, name: "original"} |> refute_assoc_loaded(:tags)
      new = %Animal{id: 5, name: "changed", tags: []} |> dirty_ignored_fields

      new
      |> assert_same_schema(old, ignoring: [:name], except: [tags: &Enum.empty?/1])

      assertion_fails(BaseMessages.stock_equality,
        [left:  pruned_animal(id: new.id, name: "changed"),
         right: pruned_animal(id: new.id, name: "original")],
        fn ->
          assert_same_schema(new, old, except: [tags: &Enum.empty?/1])
        end)
    end

    test "that the defaultly-ignored fields aren't ignored if `comparing:` is used" do
      old = %Animal{id: 5, name: "original"}
      new = %Animal{id: 5, name: "changed", tags: []} |> dirty_ignored_fields

      assert_same_schema(new, old, comparing: [:id])

      assertion_fails(BaseMessages.stock_equality,
        [left:  %{name: "changed"},
         right: %{name: "original"}],
        fn ->
          assert_same_schema(new, old, comparing: [:name])
        end)
    end

    test "in the case of `:comparing`, `:except` is still obeyed" do
      old = %Animal{id: 5, name: "original"}
      new = %Animal{id: 9, name: "original", tags: [3]} |> dirty_ignored_fields

      assertion_fails(BaseMessages.wrong_field_value(:tags),
        [left:  [3]],
         fn ->
           assert_same_schema(new, old,
             comparing: [:name],
             except: [tags: &Enum.empty?/1])
        end)
    end      

    test "note that ordinarily-suppressed fields can be checked with `comparing`" do
      old = %Animal{id: 5, name: "original", updated_at: "...time..."}
      new = %Animal{id: 5, name: "changed",  updated_at: "...another time..."}

      assertion_fails(BaseMessages.stock_equality, 
        [left:  %{id: 5, updated_at: "...another time..."},
         right: %{id: 5, updated_at: "...time..."}],
        fn ->
           assert_same_schema(new, old, comparing: [:id, :updated_at])
        end)
    end

    test "works with embedded schemas (though not needed)" do
      old = %Tag{id: 5, name: "original"}
      new = %Tag{id: 5, name: "changed"}

      assert_same_schema(new, old, ignoring: [:name])

      assertion_fails(BaseMessages.stock_equality,
        [left: new, right: old],
        fn -> 
          assert_same_schema(new, old)
        end)
    end
  end
end
