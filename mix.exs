defmodule EctoFlowAssertions.MixProject do
  use Mix.Project


  @github "https://github.com/marick/ecto_flow_assertions"
  @version "0.1.0"

  def project do
    [
      description: """
      Common Ecto schema and changeset assertions, written to be
      easily used in pipelines.
      """,
      app: :ecto_flow_assertions,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      name: "Ecto Flow Assertions",
      source_url: @github,
      docs: [
        main: "FlowAssertions.Ecto",
        extras: ["README.md"],
      ],

      package: [
        contributors: ["marick@exampler.com"],
        maintainers: ["marick@exampler.com"],
        licenses: ["Unlicense"],
        links: %{
          "GitHub" => @github
        },
      ],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:flow_assertions, "~> 0.3",
       # git: "https://github.com/marick/flow_assertions.git",
       # path: "/Users/bem/src/flow_assertions"
      },
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
