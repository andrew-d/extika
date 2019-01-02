defmodule ExTika.Mixfile do
  use Mix.Project

  def project do
    [
      app: :extika,
      description: "Wrapper around Apache Tika",
      version: "0.0.3",
      package: package(),
      elixir: "~> 1.1",
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

  defp package do
    [
      name: :extika,
      files: ["lib", "mix.exs", "README*", "LICENSE*", ".tika-version"],
      maintainers: ["Andrew Dunham"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/andrew-d/extika",
               "Docs" => "https://andrew-d.github.io/extika/"},
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.0"},

      # Development / testing dependencies
      {:dialyxir, "~> 0.5", only: :test},
      {:ex_doc, "~> 0.19", only: :dev},
    ]
  end
end


defmodule Mix.Tasks.Compile.Tika do
  @shortdoc "Downloads the Apache Tika JAR file(s)"

  def run(_) do
    version = File.read!(".tika-version")
    |> String.trim

    fetch_one(
      "tika-#{version}.jar",
      "https://archive.apache.org/dist/tika/tika-app-#{version}.jar",
      "4f377b42e122f92c3f1f3b4702029cf0642c7d6f3ce872a0dfb1472eac65be44"
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
    # Ensure the directory exists
    File.mkdir_p!(Path.dirname(dest))

    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:inets)

    # Starting an HTTP client profile allows us to scope
    # the effects of using an HTTP proxy to this function
    {:ok, _pid} = :inets.start(:httpc, [{:profile, :extika}])

    # Set proxy config.
    proxy_config()

    headers = [{'user-agent', 'ExTika/#{System.version}'}]
    request = {:binary.bin_to_list(url), headers}

    http_options = [relaxed: true] ++ proxy_auth(url)
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

  # Sets any options necessary to configure HTTP proxies
  defp proxy_config() do
    http_proxy  = System.get_env("HTTP_PROXY")  || System.get_env("http_proxy")
    https_proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
    if http_proxy,  do: proxy(http_proxy)
    if https_proxy, do: proxy(https_proxy)
  end

  defp proxy(proxy) do
    uri  = URI.parse(proxy)

    if uri.host && uri.port do
      host = String.to_charlist(uri.host)
      scheme = case uri.scheme do
        "http" -> :proxy
        "https" -> :https_proxy
      end

      :httpc.set_options([{scheme, {{host, uri.port}, []}}], :extika)
    end
  end

  defp proxy_auth(url) do
    # url scheme
    url
    |> get_scheme
    |> get_proxy_url
    |> get_proxy_auth_from_proxy_url()
  end

  defp get_scheme(url) do
    cond do
      String.starts_with?(url, "http://") -> :http
      String.starts_with?(url, "https://") -> :https
    end
  end

  defp get_proxy_url(:http) do
    System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
  end

  defp get_proxy_url(:https) do
    System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
  end

  defp get_proxy_auth_from_proxy_url(nil), do: []
  defp get_proxy_auth_from_proxy_url(proxy_url) do
    parsed = URI.parse(proxy_url)

    if parsed.userinfo do
      [username, password] = String.split(parsed.userinfo, ":", parts: 2)
      [proxy_auth: {to_charlist(username), to_charlist(password)}]
    else
      []
    end
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

  def run(_) do
    version = File.read!(".tika-version")
    |> String.trim

    names = [
      "tika-#{version}.jar",
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
