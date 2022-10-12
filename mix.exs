defmodule Googlenews.MixProject do
  use Mix.Project

  def project do
    [
      app: :googlenews,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      # {:req, "~> 0.3"},
      {:req, git: "https://github.com/un3481/req.git", tag: "0.1.0"},
      {:feeder_ex, "~> 1.1"},
      {:floki, "~> 0.33"},

      # dev
      {:ex_doc, "~> 0.28", only: :dev},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
    ]
  end
end
