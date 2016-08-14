defmodule ExTika.Mixfile do
  use Mix.Project

  def project do
    [
      app: :extika,
      description: "Wrapper around Apache Tika",
      version: "0.0.1",
      elixir: "~> 1.0",
      compilers: [:tika | Mix.compilers],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp aliases do
    [
      clean: ["clean", "clean.tika"],
    ]
  end

  defp deps do
    []
  end
end


defmodule Mix.Tasks.Compile.Tika do
  @shortdoc "Downloads the Apache Tika JAR file(s)"

  @version "1.13"

  def run(_) do
    fetch_one(
      "tika-#{@version}.jar",
      "http://www-us.apache.org/dist/tika/tika-app-#{@version}.jar",
      "e340c3fee155b93eb4033feb2302264fff3772c80a5843a047876c44eff23df7"
    )

    Mix.shell.info("Done!")
  end

  # Fetches a single file and verifies the checksum.
  defp fetch_one(fname, url, sum) do
    dest = Path.join("priv", fname)

    # If the file doesn't exist, download it.
    if !File.exists?(dest) do
      Mix.shell.info("Fetching: #{fname}")
      :ok = fetch_url(url, dest)
    end

    Mix.shell.info("Verifying checksum of: #{fname}")
    case verify_checksum(dest, sum) do
      :ok ->
        nil
      {:error, msg} ->
        Mix.shell.error(msg)
        File.rm(dest)
        exit(:checksum_mismatch)
    end

    :ok
  end

  # Streams the contents of a given URL to a file on disk
  defp fetch_url(url, dest) do
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:inets)

    # Starting an HTTP client profile allows us to scope
    # the effects of using an HTTP proxy to this function
    {:ok, _pid} = :inets.start(:httpc, [{:profile, :extika}])

    headers = [{'user-agent', 'ExTika/#{System.version}'}]
    request = {:binary.bin_to_list(url), headers}

    http_options = [relaxed: true] ++ Mix.Utils.proxy_config(url)
    options = [stream: :binary.bin_to_list(dest)]

    case :httpc.request(:get, request, http_options, options, :extika) do
      {:ok, :saved_to_file} ->
        :ok
      {:ok, {{_, status, _}, _, _}} ->
        {:remote, "httpc request failed with: {:bad_status_code, #{status}}"}
      {:error, reason} ->
        {:remote, "httpc request failed with: #{inspect reason}"}
    end

  after
    :inets.stop(:httpc, :extika)
  end

  # Verifies that the hash of a file matches what's expected
  defp verify_checksum(path, expected) do
    actual = hash_file(path)

    if actual == expected do
      :ok
    else
      {:error, """
        Data does not match the given SHA-256 checksum.

        Expected: #{expected}
          Actual: #{actual}
        """}
    end
  end

  # Hashes an input file in chunks
  defp hash_file(path) do
    File.stream!(path, [], 4 * 1024 * 1024)
    |> Enum.reduce(:crypto.hash_init(:sha256), fn(chunk, acc) ->
      :crypto.hash_update(acc, chunk)
    end)
    |> :crypto.hash_final
    |> Base.encode16(case: :lower)
  end
end


defmodule Mix.Tasks.Clean.Tika do
  @shortdoc "Cleans any downloaded JAR files"

  @version "1.13"

  def run(_) do
    names = [
      "tika-#{@version}.jar",
    ]

    Enum.each(names, fn(name) ->
      fpath = Path.join("priv", name)

      if File.exists?(fpath) do
        Mix.shell.info("Removing file: #{fpath}")
        File.rm!(fpath)
      end
    end)
  end
end
