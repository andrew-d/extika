defmodule ExTika do
  @moduledoc """
  Wrapper for Apache Tika, a toolkit that detects and extracts metadata and
  text from over a thousand different file types.
  """

  @priv_dir Path.join(Path.expand("../", __DIR__), "priv")

  @doc ~S"""
  Extracts the text from the given file.

  ## Examples

      iex> ExTika.get_text("test/test-files/test.doc")
      {:ok, "This is a DOC file.\n\n"}
  """
  @spec get_text(String.t) :: {:ok, String.t} | {:error, String.t}
  def get_text(file) do
    call_tika(file, ["--text"])
  end

  @doc ~S"""
  Extracts the text from the given file.  Fails on error.

  ## Examples

      iex> ExTika.get_text!("test/test-files/test.doc")
      "This is a DOC file.\n\n"
  """
  @spec get_text!(String.t) :: String.t
  def get_text!(file) do
    {:ok, text} = get_text(file)
    text
  end


  defp call_tika(file, flags) do
    version = Application.fetch_env!(:extika, :tika_version)
    args = [
      "-jar",
      Path.join(@priv_dir, "tika-#{version}.jar"),
    ] ++ flags ++ [file]

    case System.cmd("java", args) do
      {out, 0} ->
        {:ok, out}
      {out, code} ->
        {:error, "tika returned code #{code}: #{out}"}
    end
  end
end
