# Ecto Flow Assertions

This is a library of assertions for code that works with Ecto schemas
or changesets. It is built on top of
[`FlowAssertions`](https://hex.pm/packages/ecto_flow_assertions). It
is used to write tests in this style:

```elixir
VM.ServiceGap.accept_form(…)
|> ok_content(Changeset) 
|> assert_valid
|> assert_changes(id: 1,
                  in_service_datestring: @iso_date_1,
                  out_of_service_datestring: @iso_date_2,
                  reason: "reason")
```                  

See the [documentation](https://hexdocs.pm/ecto_flow_assertions/FlowAssertions.Ecto.html) for more.

## Installation

Add `ecto_flow_assertions` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_flow_assertions, "~> 0.1", only: :test},
  ]
end
```

