defmodule FlowAssertions.Ecto do

@moduledoc """

This is a library of assertions for code that works with Ecto schemas or changesets. It is built on top of `FlowAssertions`. 

1. Making tests easier to scan by capturing frequently-used assertions in
   functions that can be used in a pipeline.

   This library will appeal to people who prefer this:

      ```elixir
      VM.ServiceGap.accept_form(params, @institution)
      |> ok_content
      |> assert_valid
      |> assert_changes(id: 1,
                        in_service_datestring: @iso_date_1,
                        out_of_service_datestring: @iso_date_2,
                        reason: "reason")
      ```
      
   ... to this:
   
      ```elixir
      assert {:ok, changeset} = VM.ServiceGap.accept_form(params, @institution)
      assert changeset.valid?
      
      changes = changeset.changes
      assert changes.id == 1
      assert changes.in_service_datestring == @iso_date_1
      assert changes.out_of_service_datestring == @iso_date_2
      assert changes.reason == "reason"
      ```

   The key point here is that all of the `assert_*` functions in this package
   return their first argument to be used with later chained functions.

2. Error messages as helpful as those in the base ExUnit assertions:

<img src="https://raw.githubusercontent.com/marick/flow_assertions/main/pics/error2.png"/>

## Installation

Add `ecto_flow_assertions` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flow_assertions, "~> 0.1", only: :test},
  ]
end
```

Your project should also have a dependency on Ecto version 3.x.

## Use

The easiest way is `use FlowAssertions.Ecto`, which imports everything else.

If you prefer to `alias` rather than `import`, note that all the
assertion modules end in `A`. That way, there's no conflict between
the module with changeset assertions (`FlowAssertions.Ecto.ChangesetA`
and the `Ecto.Changeset` module itself.

## Reading error output

`ExUnit` has very nice reporting for assertions where a left-hand side is compared to a right-hand side, as in:


```elixir
assert x == y
```

The error output shows the values of both `x` and `y`, using
color-coding to highlight differences.

`FlowAssertions.Ecto` uses that mechanism when appropriate. However, it
does more complicated comparisons, so the words `left` and `right`
aren't strictly accurate. So, suppose you're reading errors from code
like this:

```elixir
calculation
|> assert_something(expected)
|> assert_something_else(expected)
```

In the output, `left` will refer to some value extracted from
`calculation` and `right` will refer to a value extracted from
`expected` (most likely `expected` itself).

## Related code

* `FlowAssertions` is the base upon which `FlowAssertions.Ecto` is built.

* Although it was designed for integration testing, `PhoenixIntegration` also uses
  flow-style macros. 

      test "details about form structure", %{conn: conn} do
        get_via_action(conn, :bulk_create_form)
        |> form_inputs(:bulk_animal)
        |> assert_fields(in_service_datestring: @today,
                         out_of_service_datestring: @never,
                         species_id: to_string(@bovine_id),
                         names: ~r/^\W*$/
      end

"""

  defmacro __using__(_) do
    quote do
      import FlowAssertions.Ecto.ChangesetA
      import FlowAssertions.Ecto.SchemaA
    end
  end
end
