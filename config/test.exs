import Config

config :logger, :console, 
  level: :debug,
  backends: [{Logger, :console, async: true}]

