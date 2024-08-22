## EXA Core

𝔼𝕏tr𝔸 𝔼li𝕏ir 𝔸dditions (𝔼𝕏𝔸)

EXA project index: [exa](https://github.com/red-jade/exa)

Core utilities for built-in types and features.

Module path: `Exa`

### Features

- Utilities relating to specific language modules or features:<br>   
  Binary, File, List, Map, Tuple, Set (MapSet), String,<br>
  Text (chardata), Message, Option, Process, Random, System.
  
- `Indent`: an indentable text output formatter.
  
- `Math`: floating-point arithmetic and wrappers for Erlang `:math`.
  
- `Parse`: basic combinators for simple types.

- `Factory`: for structs built by data parsers.

- `Dispatch`: _protocol_ dispatcher for tagged tuples.

- `Stopwatch`: for simple timing and benchmarking tasks.

- Trivial functions for `Http`, `Logger`.

- Type conversions.

Many Exa Core modules have the same name as the 
built-in Elixir standard library.
The idea is not to import or alias `Exa` Core, 
but always use the fully qualified module name.
It is not accidental that `Exa` is a short prefix.

### Testing

The `pkg_json` test dependency requires the `test` environment:

`$ export MIX_ENV=test`

If you do not set 'test' environment, you will see the error:

```
make: *** No rule to make target 'json.old', needed by 'old.txt'.  Stop.
** (Mix) Could not compile dependency :pkg_json, "make" command failed. 
Errors may have been logged above. 
You can recompile this dependency with "mix deps.compile pkg_json --force", 
update it with "mix deps.update pkg_json" or clean it with "mix deps.clean pkg_json"
```

### License

EXA source code is released under the MIT license.

EXA code and documentation are:<br>
Copyright (c) 2024 Mike French
