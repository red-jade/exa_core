import Config

config :logger, :console,
  level: :warning,
  backends: [{Logger, :console, async: true}]
