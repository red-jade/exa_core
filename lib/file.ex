defmodule Exa.File do
  @moduledoc "File utilities."
  require Logger
  use Exa.Constants
  import Exa.Types
  alias Exa.Types, as: E

  @doc "Test if filetype(s) indicate gzip compression."
  @spec compressed?(E.filetype() | [E.filetype()]) :: bool()

  def compressed?([]), do: false
  def compressed?(type) when is_atom(type), do: type in @compress

  def compressed?(type) when is_string(type) do
    compressed?(type |> String.downcase() |> String.to_atom())
  end

  def compressed?([type]), do: compressed?(type)
  def compressed?(types) when is_list(types), do: compressed?(List.last(types))

  @doc """
  Ensure a path directory exists. 

  The argument should be a full filename.
  If it is a truncated directory name,
  then it must end with a `'/'` to show it is already a directory,
  and should not have the last segment stripped off.

  Return the directory.
  """
  @spec ensure_dir!(E.filename()) :: E.filename()
  def ensure_dir!(filename) when is_nonempty_string(filename) do
    dir =
      cond do
        String.ends_with?(filename, "/") -> filename
        String.ends_with?(filename, "\\") -> filename
        true -> Path.dirname(filename)
      end

    if not File.exists?(dir), do: File.mkdir_p!(dir)
    dir
  end

  @doc "Ensure that a file exists."
  @spec ensure_file(E.filename()) :: :ok
  defp ensure_file!(file) do
    if not File.exists?(vfile) do
      dne = "File does not exist"
      msg = dne <> ": '#{file}'"
      Logger.error(msg, file: file)
      raise File.Error, path: file, action: dne
    end
    :ok
  end

  @doc """
  Ensure that a path ends with the required filetype. 
  Return the possibly modified path.
  """
  @spec ensure_type(E.filename(), E.filetype()) :: E.filename()
  def ensure_type(filename, type) when is_nonempty_string(filename) and is_filetype(type) do
    ext = "." <> to_string(type)
    if String.ends_with?(filename, ext), do: filename, else: filename <> ext
  end

  @doc """
  Resolve a file reference in the context of a base file or directory,
  and give the combined path relative to the current working directory.

  The file reference may be absolute or relative.
  If it is absolute, the base is ignored.
  If it is relative, it is combined with the directory of the base.

  Then the result is expressed relative to the cwd.

  ## Examples:
      iex> resolve("/foo/bar.pdf")
      "/foo/bar.pdf"
      iex> resolve("bar.pdf")
      "./bar.pdf"
      iex> resolve("./bar.pdf", "./foo/")
      "./foo/./bar.pdf"
      iex> resolve("../css/my.css", "foo/html/")
      "foo/html/../css/my.css"
  """
  @spec resolve(E.filename(), E.filename()) :: E.filename()
  def resolve(ref, base \\ "") when is_nonempty_string(ref) and is_string(base) do
    case Path.type(ref) do
      :relative -> base |> Path.dirname() |> Path.join(ref) |> Path.relative_to_cwd()
      _ -> Path.relative_to_cwd(ref)
    end
  end

  @doc """
  Split a file path into directory, filename and zero or more filetypes.

  If there is no directory segment, the `dir` result will be "." 
  (default current directory).

  The filetypes are the segments following periods '.'.
  If there is no period, the filetypes are empty `[]`.
  Multiple filetypes are provided, so that compressed files 
  have their underlying filetype recognized.

  ## Examples
      iex> split("/foo/bar.pdf")
      {"/foo", "bar", ["pdf"]}
      iex> split("myfile")
      {".", "myfile", []}
      iex> split("/usr/share/fonts/X11/font.pcf.gz")
      {"/usr/share/fonts/X11", "font", ["pcf", "gz"]}
  """
  @spec split(E.filename()) :: {dir :: Path.t(), name :: E.filename(), types :: [E.filetype()]}
  def split(filename) when is_nonempty_string(filename) do
    dir = Path.dirname(filename)

    # manually test for a directory that ends with / (unix) or \ (windows)
    name =
      if String.ends_with?(filename, "/") or String.ends_with?(filename, "\\") do
        ""
      else
        Path.basename(filename)
      end

    [name | types] = String.split(name, ".")
    {dir, name, types}
  end

  @doc """
  Merge path segments into a filename.

  The directory can be a single name, 
  or an array of directory segments.

  The filetype can be a single string,
  or a list of strings, or the empty list `[]`.
  """
  @spec join(Path.t(), E.filename(), E.filetype() | [E.filetype()]) :: E.filename()
  def join(dir, name, types) do
    dir = if is_list(dir), do: Path.join(dir), else: dir
    fname = Enum.join([name | Exa.List.enlist(types)], ".")
    dir |> Path.join(fname) |> to_string()
  end

  @doc """
  Remove UTF-8 BOM (usually generated by Microsoft tools).
  Raise errors if other BOMs are found (UTF-16, UTF-32).
  """
  @spec bom!(binary()) :: String.t()
  def bom!(str) do
    case bom(str) do
      {:no_bom, _str} -> str
      {:utf8, rest} -> rest
      {enc, _} -> raise ArgumentError, message: "Unsupported encoding, found #{enc(enc)} BOM"
    end
  end

  defp enc(:utf16be), do: "UTF-16 BE"
  defp enc(:utf16le), do: "UTF-16 LE"
  defp enc(:utf32be), do: "UTF-32 BE"
  defp enc(:utf32le), do: "UTF-32 LE"

  @doc """
  Remove BOM and return the implied encoding, if any.
  """
  @spec bom(binary()) :: {E.bom_encoding(), String.t()}
  def bom(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: {:utf8, rest}
  def bom(<<0xFE, 0xFF, rest::binary>>), do: {:utf16be, rest}
  def bom(<<0xFF, 0xFE, rest::binary>>), do: {:utf16le, rest}
  def bom(<<0x00, 0x00, 0xFE, 0xFF, rest::binary>>), do: {:utf32be, rest}
  def bom(<<0xFF, 0xFE, 0x00, 0x00, rest::binary>>), do: {:utf32le, rest}
  def bom(txt), do: {:no_bom, txt}

  @doc """
  Write binary data to file.
  Optionally compress the file using gzip,
  if the filetype is 'gz' or 'gzip'.
  """
  @spec to_file_binary(binary(), E.filename()) :: E.filename() | {:error, any()}
  def to_file_binary(bin, filename) when is_binary(bin) do
    filename |> fopts_write_path!(false) |> write_binary(bin)
  rescue
    err -> {:error, err}
  end

  @doc """
  Read a binary file as a single binary.
  The binary is not processed or modified in any way.

  The content could be encoded binary or text.

  Any Byte Order Marks (BOMs) are not processed. 
  Consider using `&bom/1` or `&bom!/1` to read and strip the BOM.
  """
  @spec from_file_binary(E.filename()) :: binary() | {:error, any()}
  def from_file_binary(filename) when is_filename(filename) do
    filename |> fopts_read_path!(false) |> read_binary()
  rescue
    err -> {:error, err}
  end

  @doc """
  Compress a file. Write the compressed file to the output directory.
  If the output directory is `nil`, default to the input directory.

  Return the output name of the compressed binary file.
  The file will be given a `".#{hd(@compress)}"` filetype suffix.
  """
  @spec compress(E.filename(), nil | E.filename()) :: E.filename() | {:error, any()}
  def compress(filename, outdir \\ nil)
      when is_filename(filename) and
             (is_nil(outdir) or is_filename(outdir)) do
    {dir, name, types} = split(filename)
    outdir = if is_nil(outdir), do: dir, else: outdir

    cond do
      compressed?(types) ->
        {:error, "File is already compressed: '#{filename}'"}

      true ->
        outfile = join(outdir, name, types ++ [hd(@compress)])

        case from_file_binary(filename) do
          {:error, _} = err -> err
          bin -> to_file_binary(bin, outfile)
        end
    end
  end

  @doc """
  Decompress a file. Write the decompressed file to the output directory.
  If the output directory is `nil`, default to the input directory.

  Return the output name of the decompressed binary file.
  The file will be given a `".#{hd(@compress)}"` filetype suffix.
  """
  @spec decompress(E.filename(), nil | E.filename()) :: E.filename()
  def decompress(filename, outdir \\ nil)
      when is_filename(filename) and (is_nil(outdir) or is_filename(outdir)) do
    {dir, name, types} = split(filename)
    outdir = if is_nil(outdir), do: dir, else: outdir
    ntype = length(types)

    if not compressed?(types) do
      {:error, "File is not compressed: '#{filename}'"}
    else
      outfile = join(outdir, name, Enum.take(types, ntype - 1))

      case from_file_binary(filename) do
        {:error, _} = err -> err
        bin -> to_file_binary(bin, outfile)
      end
    end
  end

  @doc """
  Write text data to file in UTF-8 format.
  Optionally compress the file using gzip,
  if the filetype is 'gz' or 'gzip'.
  """
  @spec to_file_text(IO.chardata(), E.filename()) :: IO.chardata()
  def to_file_text(iodata, filename) when is_nonempty_string(filename) do
    ensure_dir!(filename)
    {path, fopts} = fopts_write_path!(filename, true)
    file = File.open!(path, fopts)
    IO.write(file, iodata)
    File.close(file)
    iodata
  end

  @doc """
  Read a file as a single UTF-8 binary String,
  optionally trimming each line, and removing 
  comments or blank lines.

  See `&from_file_lines/2` for options.
  """
  @spec from_file_text(E.filename(), E.options()) :: String.t() | {:error, any()}
  def from_file_text(filename, opts \\ []) when is_nonempty_string(filename) do
    params = options(opts, false)

    try do
      case filename |> fopts_read_path!(true) |> read_utf8(params) do
        str when is_string(str) -> bom!(str)
        {:error, err} -> recover_error(filename, params, err)
      end
    rescue
      err -> recover_error(filename, params, err)
    end
  end

  @doc """
  Read a text file as lines,
  optionally with comments and blank lines removed.
  optionally trimming each line, and removing 
  comments or blank lines.

  If the filetypes end with `.gz` or `.gzip`,
  the file will be gzip decompressed.

  Options:
  - `:comments` a list of string prefixes to remove the line
  - `:trim` to trim each line of whitespace
  - `:blank` to remove blank lines (after trimming)
  - `:replace` a replacement character for bad UTF8 format

  If any comment prefixes are provided,
  the default trim and blank values are `true` 
  (trim, filter blanks), assuming code.

  Note that trim and blank may remove significant 
  whitespace within multiline quoted strings.

  If no comment prefixes are provided,
  the default trim and blank values are `false` 
  (no trim, keep blanks), assuming text.

  On error, re-read the file as binary,
  dump out all the non-UTF8 byte sequences,
  and try to patch the file with a replacement character.

  The default replacement character is `*` 
  to keep ASCII-as-ASCII for downstream processing,
  but you may pass `0xFFFD` as the standard 
  Unicode replacement character.
  """
  @spec from_file_lines(E.filename(), E.options()) :: [String.t()] | {:error, any()}
  def from_file_lines(filename, opts \\ []) when is_nonempty_string(filename) do
    params = options(opts, true)

    try do
      case filename |> fopts_read_path!(true) |> read_utf8(params) do
        [] -> []
        [line | lines] -> [bom!(line) | lines]
        {:error, err} -> recover_error(filename, params, err)
      end
    rescue
      err -> recover_error(filename, params, err)
    end
  end

  # -----------------
  # private functions
  # -----------------

  # get text file parameters from options
  # comments: a list of comment line prefix strings
  # trim: flag, if true, each line is trimmed
  # blank: flag, if true, empty lines are filtered out
  # split: flag, if true, output list of lines, else output single text string
  # replace: replacement character for patching broken UTF8 streams

  @spec options(E.options(), bool()) :: map()
  defp options(opts, split?) do
    # defaults for blank lines and trimming lines depends on comments
    comments = Exa.Option.get_list_nonempty_string(opts, :comments, [])
    has_comms? = comments != []

    %{
      :comments => comments,
      :trim => Exa.Option.get_bool(opts, :trim, has_comms?),
      :blank => Exa.Option.get_bool(opts, :blank, has_comms?),
      :replace => Exa.Option.get_char(opts, :replace, ?*),
      :split => split?
    }
  end

  # format filetypes for log message
  @spec format([E.filetype()]) :: String.t()
  defp format(types), do: types |> Enum.map(&String.upcase/1) |> Enum.join(" ")

  # validate a read, and build options
  @spec fopts_read_path!(E.filename(), bool()) :: {E.filename(), [atom(), ...]}
  defp fopts_read_path!(filename, text?) do
    if not File.exists?(filename) do
      dne = "File does not exist"
      msg = dne <> ": '#{filename}'"
      Logger.error(msg, file: filename)
      raise File.Error, path: filename, action: dne
    end

    {_dir, _name, types} = split(filename)
    fopts = [:read]
    fopts = if compressed?(types), do: [:compressed | fopts], else: fopts
    fopts = if text?, do: [:utf8 | fopts], else: [:binary | fopts]
    Logger.info("Read #{format(types)} file: '#{Path.basename(filename)}'", file: filename)
    {filename, fopts}
  end

  # validate a write, and build options
  @spec fopts_write_path!(E.filename(), bool()) :: {E.filename(), [atom(), ...]}
  defp fopts_write_path!(filename, text?) do
    {dir, name, types} = split(filename)
    ensure_dir!(dir)
    Logger.info("Write #{format(types)} file: '#{Path.basename(filename)}'", file: filename)
    # remove illegal punctuation, convert space to '_', truncate for file system
    name = Exa.String.sanitize!(name, 200, true)
    path = join(dir, name, types)
    fopts = [:write]
    fopts = if compressed?(types), do: [:compressed | fopts], else: fopts
    fopts = if text?, do: [:utf8 | fopts], else: [:binary | fopts]
    {path, fopts}
  end

  # read binary, compare expected and actual size
  @spec read_binary({E.filename(), [atom()]}) :: binary() | {:error, any()}
  defp read_binary({filename, fopts}) do
    # no comments, and don't require lines, so just read binary string

    case filename |> File.open!(fopts) |> IO.binread(:eof) do
      {:error, _} = err ->
        err

      buf when is_binary(buf) ->
        if :compressed not in fopts do
          {:ok, stat} = File.stat(filename)
          exp = stat.size
          act = byte_size(buf)

          if exp != act do
            Logger.warning("Read size mismatch, expect #{exp}, found #{act}", file: filename)
          end
        end

        buf
    end
  end

  # write binary, compare final and actual size for compressed output
  @spec write_binary({E.filename(), [atom()]}, binary()) :: E.filename()
  defp write_binary({filename, fopts}, bin) do
    file = File.open!(filename, fopts)
    :ok = IO.binwrite(file, bin)
    File.close(file)

    if :compressed in fopts do
      {:ok, stat} = File.stat(filename)
      comp = round(100.0 * stat.size / byte_size(bin))
      Logger.info("Compression #{comp}% of original size", file: filename)
    end

    filename
  end

  # read text 

  @spec read_utf8({E.filename(), [atom()]}, map()) :: String.t() | [String.t()] | {:error, any()}

  defp read_utf8(
         {path, opts},
         %{:comments => [], :trim => false, :blank => false, :split => false}
       ) do
    # no comments, and don't require lines, so just read utf8 string
    path |> File.open!(opts) |> IO.read(:eof)
  end

  defp read_utf8(
         {path, opts},
         %{:comments => comms, :trim => trim?, :blank => blank?, :split => split?}
       ) do
    path
    |> File.stream!(opts, :line)
    |> trim(trim?)
    |> filter(blank?, comms)
    |> splits(split?)
  end

  # try to patch UTF8 - slow

  @spec recover_error(E.filename(), map(), any()) :: String.t() | [String.t()]

  defp recover_error(filename, params, %UndefinedFunctionError{
         module: :unicode,
         function: :format_error
       }) do
    Logger.error("Recovering file '#{filename}': unicode format error", file: filename)
    recover_text(filename |> from_file_binary() |> Exa.String.patch_utf8(), params)
  end

  defp recover_error(_filename, _params, err), do: {:error, err}

  @spec recover_text(String.t(), map()) :: String.t() | [String.t()]

  defp recover_text(
         text,
         %{:comments => [], :trim => false, :blank => false, :split => false}
       ),
       do: text

  defp recover_text(
         text,
         %{:comments => comms, :trim => trim?, :blank => blank?, :split => split?}
       ) do
    text
    |> StringIO.open()
    |> elem(1)
    |> IO.stream(:line)
    |> trim(trim?)
    |> filter(blank?, comms)
    |> splits(split?)
  end

  @spec trim(IO.Stream.t() | File.Stream.t(), bool()) :: Enumerable.t()
  defp trim(stream, false), do: Stream.map(stream, &String.trim_trailing(&1, "\n"))
  defp trim(stream, true), do: Stream.map(stream, &String.trim/1)

  @spec filter(Enumerable.t(), bool(), [String.t()]) :: Enumerable.t()
  defp filter(stream, false, []), do: stream
  defp filter(stream, blank?, comms), do: Stream.filter(stream, &keep?(&1, blank?, comms))

  # join with space? or newline?
  @spec splits(Enumerable.t(), bool()) :: String.t() | [String.t()]
  defp splits(stream, false), do: Enum.join(stream, " ")
  defp splits(stream, true), do: Enum.map(stream, & &1)

  # blank flag is to filter, so opposite sense of keep 
  @spec keep?(String.t(), bool(), [String.t()]) :: bool()
  defp keep?("", blank?, _), do: not blank?
  defp keep?(str, _, comms), do: comm?(str, comms)

  @spec comm?(String.t(), [String.t()]) :: bool()
  defp comm?(_, []), do: true
  defp comm?(s, [c | t]), do: if(String.starts_with?(s, c), do: false, else: comm?(s, t))
end
