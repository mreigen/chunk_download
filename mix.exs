defmodule Download.Mixfile do
  use Mix.Project

  @project_url "https://github.com/mreigen/elixir_chunk_download"
  @version "0.0.1"

  def project do
    [
      app: :download,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: @project_url,
      homepage_url: @project_url,
      description:
        "Uses HTTPoison's Async modules to download a file in chunks asynchronously. It also uses background processes to execute the download streaming. ",
      package: package(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths() ++ []
  defp elixirc_paths(_), do: elixirc_paths()
  defp elixirc_paths, do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [applications: [:httpoison]]
  end

  defp deps do
    [
      {:httpoison, ">= 1.5.1"}
    ]
  end

  defp package() do
    [
      name: :download,
      files: ["lib/**/*.ex", "mix.exs"],
      maintainers: ["Minh Reigen"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @project_url,
        "Author's blog" => "http://minhreigen.com"
      }
    ]
  end
end
