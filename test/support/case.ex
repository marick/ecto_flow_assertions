defmodule FlowAssertions.Ecto.Case do

  defmacro __using__(_) do 
    quote do 
      use ExUnit.Case, async: true
      alias ExUnit.AssertionError

      use FlowAssertions
      use FlowAssertions.Ecto
      import FlowAssertions.AssertionA
      alias FlowAssertions.Ecto.Messages
    end  
  end
end
