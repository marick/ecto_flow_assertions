defmodule FlowAssertions.Ecto.ChangesetATest do
  use FlowAssertions.Ecto.Case
  use Ecto.Schema
  import Ecto.Changeset
  alias FlowAssertions.Messages, as: BaseMessages

  embedded_schema do
    field :name, :string
    field :tags, {:array, :string}
  end

  def changeset(thing, attrs) do
    thing
    |> cast(attrs, [:name, :tags])
    |> validate_required([:name])
  end

  setup do
    [valid: %__MODULE__{name: "Bossie", tags: ["cow"]}]
  end

  test "pure booleans" do
    invalid = %__MODULE__{} |> changeset(%{})
    valid = %__MODULE__{} |> changeset(%{name: "Bossie"})
    
    assert assert_invalid(invalid) == invalid
    assert assert_valid(valid) == valid

    assertion_fails(Messages.changeset_invalid,
      [left: invalid],
      fn ->
        assert_valid(invalid)
      end)

    assertion_fails(Messages.changeset_valid,
      [left: valid],
      fn ->
        assert_invalid(valid)
      end)
  end

  describe "changes" do
    test "successful checking for change existence", %{valid: valid} do
      changeset(valid, %{name: "new", tags: []})
      |> assert_changes(name: "new", tags: [])
      # don't have to give a value
      |> assert_changes([:name, :tags])
      # fields don't have to be mentioned
      |> assert_changes(name: "new")
      |> assert_changes([:name])
      # assert_change variant
      |> assert_change(:name)
    end

    test "failure cases", %{valid: valid} do
      assertion_fails(BaseMessages.field_missing(:name),
        [left: %{}],
        fn -> 
          changeset(valid, %{name: valid.name})
          |> assert_changes(name: valid.name)
        end)
      
      assertion_fails(BaseMessages.wrong_field_value(:name),
        [left: "wrong new name", right: "right new name"],
        fn -> 
          changeset(valid, %{name: "wrong new name"})
          |> assert_changes(name: "right new name")
        end)
    end
  end

  describe "lack of changes" do
    test "assert no changes anywhere", %{valid: valid} do
      changeset(valid, %{tags: "wrong"})
      |> assert_invalid
      |> assert_no_changes

      changeset = changeset(valid, %{tags: ["tag"]})
      assertion_fails(Messages.some_field_changes(changeset),
        [left: changeset],
        fn -> 
          assert_no_changes(changeset)
        end)
    end

    test "assert particular values are unchanged", %{valid: valid} do
      changeset(valid, %{name: "new name"})
      |> assert_valid
      |> assert_no_changes([:tags])
      |> assert_no_changes(:tags)

      bad_changeset = changeset(valid, %{name: "new name"})
      assertion_fails(Messages.bad_field_change(:name),
        [left: bad_changeset],
        fn -> 
          assert_no_changes(bad_changeset, [:name])
        end)
    end

    test "will object to an impossible field", %{valid: valid} do
      assertion_fails(BaseMessages.required_key_missing(:gorp, %__MODULE__{}),
        fn -> 
          changeset(valid, %{})
          |> assert_no_changes([:gorp, :foop])
        end)
    end
  end
  
  describe "the existence of errors" do
    test "yes, the error is there", %{valid: valid} do
      changeset(valid, %{tags: "wrong", name: ""})
      |> assert_errors([:tags, :name])
      # You don't have to speak to all errors
      |> assert_errors([:tags])
      |> assert_errors([:name])

      # assert_error variant
      |> assert_error(:tags)
      |> assert_error([:tags])
    end
      
    test "there is no error at all", %{valid: valid} do
      changeset = changeset(valid, %{name: "new name"})
      assertion_fails(Messages.no_error_for_field(:name),
        [left: changeset],
        fn -> 
          assert_error(changeset, :name)
        end)
    end

    test "that field doesn't have an error", %{valid: valid} do
      changeset = changeset(valid, %{tags: "wrong"})
      assertion_fails(Messages.no_error_for_field(:name),
        [left: changeset],
        fn -> 
          assert_error(changeset, :name)
        end)
    end
  end    
    
  describe "specific error messages" do
    test "yes, the error is there", %{valid: valid} do
      changeset(valid, %{tags: "wrong", name: ""})
      |> assert_error(tags: "is invalid")
      |> assert_error(name: "can't be blank")
      |> assert_error(
           tags: "is invalid",
           name: "can't be blank")
    end

    test "there is no error at all", %{valid: valid} do
      changeset = changeset(valid, %{name: "new name"})
      
      assertion_fails(Messages.no_error_for_field(:tags),
        [left: changeset],
        fn -> 
          assert_error(changeset, tags: "is invalid")
        end)
    end

    test "that field doesn't have an error", %{valid: valid} do
      changeset = changeset(valid, %{tags: "wrong"})
      
      assertion_fails(Messages.no_error_for_field(:name),
        [left: changeset],
        fn -> 
          assert_error(changeset, name: "can't be blank")
        end)
    end

    test "that field has a different error", %{valid: valid} do
      changeset = changeset(valid, %{tags: "wrong"})
          
      assertion_fails(Messages.not_right_error_message(:tags),
        [left: ["is invalid"],
         right: "this is the expected message"],
        fn -> 
          assert_error(changeset, tags: "this is the expected message")
        end)
    end

    test "you can ask for all of a list of errors", %{valid: valid} do 
      changeset =
        changeset(valid, %{tags: "wrong"})
        |> add_error(:tags, "added error 1")
        |> add_error(:tags, "not checked")

      changeset 
      |> assert_error(tags: "added error 1")
      |> assert_error(tags: ["is invalid", "added error 1"])

      assertion_fails(Messages.not_right_error_message(:tags),
        [left: ["not checked", "added error 1", "is invalid"],
         right: "not present"],
        fn ->
          assert_error(changeset, tags: ["is invalid", "not present"])
        end)
    end
  end

  # describe "asserting there is no error" do
  #   test "success case", %{valid: valid} do
  #     changeset(valid, %{})
  #     |> assert_valid
  #     |> assert_error_free([:tags, :name])
  #     |> assert_error_free( :tags)
  #   end

  #   test "field does have an error", %{valid: valid} do
  #     assertion_fails(
  #       ["There is an error for field `:tags`"],
  #       fn -> 
  #         changeset(valid, %{tags: "bogus"})
  #         |> assert_invalid
  #         |> assert_error_free(:tags)
  #       end)
  #   end

  #   @tag :skip
  #   test "will object to an impossible field", %{valid: valid} do
  #     assertion_fails(
  #       ["Test error: there is no key `:gorp` in Crit.Assertions.ChangesetTest"],
  #       fn -> 
  #         changeset(valid, %{tags: "bogus"})
  #         |> assert_error_free(:gorp)
  #       end)
  #   end
  # end

  # describe "testing the data part" do
  #   test "equality comparison", %{valid: valid} do
  #     changeset(valid, %{})
  #     |> assert_data(name: valid.name)
  #     |> assert_data(tags: valid.tags)
  #     |> assert_data(name: valid.name, tags: valid.tags)
  #   end

  #   @tag :skip
  #   test "shape comparison" do
  #     assert %PermissionList{}.view_reservations == true # default

  #     (fresh = UserApi.fresh_user_changeset)
  #     |> assert_data_shape(:permission_list, %{})
  #     |> assert_data_shape(:permission_list, %PermissionList{})
  #     |> assert_data_shape(:permission_list,
  #                          %PermissionList{view_reservations: true})

  #     assertion_fails(
  #       ["The value doesn't match the given pattern"],
  #       fn -> 
  #         assert_data_shape(fresh, :permission_list, %User{})
  #       end)
      
  #     assertion_fails(
  #       ["The value doesn't match the given pattern"],
  #       fn -> 
  #         assert_data_shape(fresh, :permission_list,
  #           %PermissionList{view_reservations: false})
  #       end)
  #   end
  # end
end
