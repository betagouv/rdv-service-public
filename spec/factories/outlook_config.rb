FactoryBot.define do
  factory :outlook_config do
    agent
    microsoft_graph_token { "token" }
    microsoft_graph_refresh_token { "refresh_token" }
  end
end
