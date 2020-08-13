defmodule FlowAssertions.Ecto.MiscATest do
  use FlowAssertions.Ecto.Case

  defmodule Tag do 
    use Ecto.Schema
    embedded_schema do
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
      assert_assoc_loaded(%Animal{}, :name)
      refute_assoc_loaded(%Animal{}, :tags)

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
  end

end
