## EXA Core

𝔼𝕏tr𝔸 𝔼li𝕏ir 𝔸dditions (𝔼𝕏𝔸)

EXA project index: [exa](https://github.com/red-jade/exa)

Module path: `Exa`

Features:

- Utilities relating to specific language modules or features:<br>   
  Binary, File, List, Map, Tuple, Set (MapSet), String,
  Text (chardata), Message, Option, Process, Random, System.
  
- `Indent`: an indentable text output formatter.
  
- `Math`: floating-point arithmetic and wrappers for Erlang `:math`.
  
- `Parse`: basic combinators for simple types.

- `Factory`: for structs built by data parsers.

- `Stopwatch`: for simple timing and benchmarking tasks.

- Trivial functions for `Http`, `Logger`.

- Type conversions.

Many Exa Core modules have the same name as the 
built-in Elixir standard library.
The idea is not to import or alias `Exa` Core, 
but always use the fully qualified module name.
It is not accidental that `Exa` is a short prefix.

## Testing

The `pkg_json` test dependency requires the `test` environment:

`$ export MIX_ENV=test`

## License

Exa source code is released under the MIT license.

Exa code and documentation are:
Copyright (C) 2024 Mike French
