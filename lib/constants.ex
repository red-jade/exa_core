defmodule Exa.Constants do
  @moduledoc """
  Constants for EXA libraries.
  """

  import Bitwise

  defmacro __using__(_) do
    quote do
      # default fields for parsing null and boolean values
      @nulls ["", "nil", "null", "nan", "inf"]
      @falses ["false", "f"]
      @trues ["true", "t"]

      # default locale
      @default_locale_name "en_US"
      @default_locale {:en, :US, nil, nil}

      # maximum elapsed time (ms) to limit a compute process
      # when time_limit is an argument to an expiring computation
      # this value is the default and also the maximum limit for the argument
      @max_duration 20_000

      # runtime private data for distribution
      @priv_dir :code.priv_dir(:exa)

      # default i18n base directories for gettext and properties
      @i18n_base_dir [@priv_dir, "i18n"]
      @gettext_base_dir [@priv_dir, "gettext"]
      @properties_base_dir [@priv_dir, "properties"]

      # common filetypes
      @filetype_txt :txt
      @filetype_md :md

      # list of filetypes indicating gzip compression
      # the head of the list is used for output
      @compress [:gz, :gzip]

      # empty set
      @empty_set MapSet.new()

      # standard form for an empty range
      @empty_range 0..1//-1

      # character sets for end-of-line and whitespace

      @ascii_eol [?\n, ?\r, ?\f, ?\v]
      @ascii_ws [?\s, ?\t | @ascii_eol]

      @uni_eol @ascii_eol ++ [0x85, 0x2028, 0x2029]
      @uni_ws @ascii_ws ++
                [
                  0xA0,
                  0x202F,
                  0x205F,
                  0x3000,
                  0x2000,
                  0x2001,
                  0x2002,
                  0x2003,
                  0x2004,
                  0x2005,
                  0x2006,
                  0x2007,
                  0x2008,
                  0x2009,
                  0x200A
                ]

      # safe characters for files on Windows and Linux 
      # allow alphanum and at least these safe characters
      # note the missing bad characters for Windows:
      # < > \ / ' " : | ? *
      @safe_file ~c'_.,;-+(){}[]~!@#$%^&='

      # math constants (15dp for double precision)

      @pi 3.141592653589793
      @e 2.718281828459045

      @pi_2 @pi / 2.0
      @pi_180 @pi / 180.0

      # default epsilon for approximate floating-point arithmetic

      @epsilon 1.0e-6

      # min and max for types with specific length

      @min_uint 0
      @max_uint4 (1 <<< 4) - 1
      @max_uint8 (1 <<< 8) - 1
      @max_uint10 (1 <<< 10) - 1
      @max_uint12 (1 <<< 12) - 1
      @max_uint16 (1 <<< 16) - 1
      @max_uint32 (1 <<< 32) - 1
      @max_uint64 (1 <<< 64) - 1

      @min_int8 0 - (1 <<< 7)
      @max_int8 (1 <<< 7) - 1

      @min_int10 0 - (1 <<< 9)
      @max_int10 (1 <<< 9) - 1

      @min_int12 0 - (1 <<< 11)
      @max_int12 (1 <<< 11) - 1

      @min_int16 0 - (1 <<< 15)
      @max_int16 (1 <<< 15) - 1

      @min_int32 0 - (1 <<< 31)
      @max_int32 (1 <<< 31) - 1

      @min_int64 0 - (1 <<< 63)
      @max_int64 (1 <<< 63) - 1

      @min_f32 -3.4028234664e38
      @max_f32 3.4028234664e38

      @min_f64 -1.7976931348623157e308
      @max_f64 1.7976931348623157e308
    end
  end
end
