defmodule GoogleNews.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/un3481/exgooglenews"
  @maintainers ["Anthony Freitas"]

  def project do
    [
      name: "Google News",
      app: :google_news,
      version: @version,
      elixir: "~> 1.12",
      package: package(),
      source_url: @url,
      maintainers: @maintainers,
      description: "An Elixir wrapper of the Google News RSS feed.",
      homepage_url: @url,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.3.2"},
      {:feeder_ex, "~> 1.1"},
      {:floki, "~> 0.33"},

      # dev
      {:ex_doc, "~> 0.28", only: :dev},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},

      # test
      {:mox, "~> 0.5.2", only: :test}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @url
    ]
  end

  defp package do
    [
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{github: @url},
      files: ~w(lib) ++ ~w(LICENSE mix.exs README.md)
    ]
  end
end
