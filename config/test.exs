import Config

config :exslack,
  access_token: System.get_env("SLACK_TEST_ACCOUNT_ACCESS_TOKEN")

config :tesla, adapter: Tesla.Mock
