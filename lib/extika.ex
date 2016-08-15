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

  @doc ~S"""
  Returns the language of the document.

  ## Examples

      iex> ExTika.get_language("test/test-files/test.doc")
      {:ok, "en"}
  """
  @spec get_language(String.t) :: String.t
  def get_language(file) do
    case call_tika(file, ["--language"]) do
      {:ok, lang} ->
        {:ok, ExTika.Utils.trim(lang)}
      {:err, msg} ->
        {:ok, msg}
    end
  end

  @doc ~S"""
  Returns the language of the document.  Fails on error.

  ## Examples

      iex> ExTika.get_language!("test/test-files/test.doc")
      "en"
  """
  @spec get_language!(String.t) :: String.t
  def get_language!(file) do
    {:ok, lang} = get_language(file)
    lang
  end

  @doc ~S"""
  Returns the content type of the document.

  ## Examples

      iex> ExTika.get_content_type("test/test-files/test.doc")
      {:ok, "application/msword"}
  """
  @spec get_content_type(String.t) :: String.t
  def get_content_type(file) do
    case call_tika(file, ["--detect"]) do
      {:ok, lang} ->
        {:ok, ExTika.Utils.trim(lang)}
      {:err, msg} ->
        {:ok, msg}
    end
  end

  @doc ~S"""
  Returns the content type of the document.  Fails on error.

  ## Examples

      iex> ExTika.get_content_type!("test/test-files/test.doc")
      "application/msword"
  """
  @spec get_content_type!(String.t) :: String.t
  def get_content_type!(file) do
    {:ok, lang} = get_content_type(file)
    lang
  end

  ##################################################
  ## HELPER FUNCTIONS

  defp call_tika(file, flags) do
    {:ok, version} = Application.fetch_env(:extika, :tika_version)
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
