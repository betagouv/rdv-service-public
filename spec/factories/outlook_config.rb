FactoryBot.define do
  factory :outlook_config do
    agent
    microsoft_graph_token { "token" }
    refresh_microsoft_graph_token { "refresh_token" }
  end
end
