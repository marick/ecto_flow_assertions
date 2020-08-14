defmodule FlowAssertions.Ecto.SchemaATest do
  use FlowAssertions.Ecto.Case
  alias FlowAssertions.Messages, as: BaseMessages
  

  defmodule Tag do 
    use Ecto.Schema
    schema "tags" do
      field :name, :string
    end
  end

  defmodule Animal do
    use Ecto.Schema
    embedded_schema do
      field :name, :string
      has_many :tags, Tag
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
      assert assert_schema_name(%Tag{}, Tag) == %Tag{}

      assertion_fails(BaseMessages.stock_equality,
        [left: Tag, right: Animal],
        fn -> 
          assert_schema_name(%Tag{}, Animal)
        end)
    end

    test "embedded schemas don't have a meta" do
      assertion_fails(Messages.maybe_embedded,
        [left: %Animal{}],
        fn ->
          assert_schema_name(%Animal{}, Tag)
        end)
    end

    test "none-structs aren't even close to being right" do
      assertion_fails(Messages.never_a_schema,
        [left: %{}],
        fn ->
          assert_schema_name(%{}, Tag)
        end)
    end
  end
end
