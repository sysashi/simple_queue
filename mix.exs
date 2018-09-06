defmodule SQ.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_queue,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SQ.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exquisite, github: "meh/exquisite", branch: "master", override: true},
      {:amnesia, github: "meh/amnesia", branch: "master"}
    ]
  end
end
