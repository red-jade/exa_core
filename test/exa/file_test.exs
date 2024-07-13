defmodule Exa.FileTest do
  use ExUnit.Case
  import Exa.File

  doctest Exa.File

  @in_dir ["test", "input", "txt"]
  @out_dir ["test", "output", "txt"]

  @filetypes_json_gz ["json", "gz"]
  @pkg_json_dir "deps/pkg_json/testdata"

  defp in_file(name, type), do: Exa.File.join(@in_dir, name, type)

  defp out_file(name, types), do: Exa.File.join(@out_dir, name, types)

  defp pkg_file(name), do: Exa.File.join(@pkg_json_dir, name, @filetypes_json_gz)

  test "type" do
    assert "foo.dot" = ensure_type("foo", "dot")
    assert "/data/foo.dot" == ensure_type("/data/foo", "dot")
    assert "/data/.gitignore" == ensure_type("/data/", "gitignore")
    assert "/data/foo.txt.gz" == ensure_type("/data/foo.txt", "gz")
  end

  test "read file error" do
    dne = "File does not exist"
    in_file = in_file("xyz", "txt")
    {:error, %File.Error{path: ^in_file, action: ^dne}} = from_file_lines(in_file)
  end

  test "read file" do
    # default for comments is to trim and filter blank lines
    lines = from_file_lines(in_file("basic", "txt"), comments: ["#", "--", "//"])

    assert [
             "First line, perhaps the title.",
             "content, blah",
             "more, lorem ipsum",
             "the finale"
           ] == lines

    # write compressed 
    lines
    |> Enum.join("\n")
    |> to_file_text(out_file("basic", ["txt", "gz"]))
  end

  test "read file no comments" do
    # no comments means default false for trim and filter blank
    lines = from_file_lines(in_file("basic", "txt"))

    assert [
             "First line, perhaps the title.",
             "",
             "# a hash comment",
             "",
             "content, blah",
             "more, lorem ipsum",
             "",
             "-- another comment",
             "// and another",
             "",
             "the finale",
             ""
           ] == lines
  end

  test "read file joined" do
    text = from_file_lines(in_file("basic", "txt"), trim: true, blank: true)

    assert [
             "First line, perhaps the title.",
             "# a hash comment",
             "content, blah",
             "more, lorem ipsum",
             "-- another comment",
             "// and another",
             "the finale"
           ] == text
  end

  test "read file text raw" do
    text = from_file_text(in_file("basic", "txt"))

    assert Enum.join(
             [
               "First line, perhaps the title.",
               "",
               "# a hash comment",
               "",
               "content, blah",
               "more, lorem ipsum",
               "",
               "-- another comment",
               "// and another",
               "",
               "the finale",
               "",
               ""
             ],
             "\n"
           ) == text
  end

  test "read file text trimmed" do
    text = from_file_text(in_file("basic", "txt"), trim: true, blank: true)

    assert Enum.join(
             [
               "First line, perhaps the title.",
               "# a hash comment",
               "content, blah",
               "more, lorem ipsum",
               "-- another comment",
               "// and another",
               "the finale"
             ],
             " "
           ) == text
  end

  test "utf8 error text" do
    from_file_text(in_file("tomats", "txt"))
  end

  test "utf8 error lines" do
    lines = from_file_lines(in_file("tomats", "txt"))
    assert 1273 == length(lines)
  end

  test "compressed read" do
    lines = from_file_lines(pkg_file("example"))
    assert 415 == length(lines)
  end
end
