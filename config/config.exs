import Config

config :logger, :console, format: {Exa.Logger, :format}

import_config "#{config_env()}.exs"
