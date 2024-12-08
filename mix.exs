defmodule Klf200.MixProject do
  use Mix.Project

  def project do
    [
      app: :klf200,
      version: "0.1.0",
      name: "klf200",
      description: "A client for the VELUX klf200 API",
      source_url: "https://github.com/emischorr/klf200",
      homepage_url: "https://github.com/emischorr/klf200",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        # The main page in the docs
        main: "klf200",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ]
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
      {:socket, "~> 0.3"}
    ]
  end

  defp package() do
    [
      name: "klf200",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/emischorr/klf200"}
    ]
  end
end
