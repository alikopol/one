defmodule One.MixProject do
  use Mix.Project

  def project do
    [
      app: :one,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_uuid, "~> 1.2"},
      {:jason, "~> 1.0"},
      {:poison, "~> 4.0"},
      {:tesla, "~> 1.3.0"},
      {:hackney, "~> 1.15.2"},
      {:timex, "~>3.6.1"},
      {:ex_doc, "~> 0.21.1"}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/alikopol/one"
    ]
  end
end
