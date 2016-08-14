defmodule ExTikaTest do
  use ExUnit.Case
  doctest ExTika

  @files_dir Path.join(Path.expand(__DIR__), "test-files")

  test "get_text" do
    get_text = fn(name) ->
      name
      |> test_file
      |> ExTika.get_text
      |> trim
    end

    assert get_text.("test.doc") == {:ok, "This is a DOC file."}
    assert get_text.("test.docx") == {:ok, "This is a DOCX file."}
  end

  test "get_text!" do
    text = "test.doc"
            |> test_file
            |> ExTika.get_text!
            |> String.trim
    assert text == "This is a DOC file."
  end


  defp trim({:ok, text}) do
    {:ok, trim(text)}
  end

  defp trim({:error, msg}) do
    {:error, msg}
  end

  defp trim(s) when is_binary(s) do
    if :erlang.function_exported(String, :trim, 1) do
      String.trim(s)
    else
      String.strip(s)
    end
  end

  defp test_file(name) do
    Path.join(@files_dir, name)
  end
end
