FactoryBot.define do
  factory :instance_export do
    source_organisation { association(:organisation) }
    agent

    api_token { "fake-api-token" }
    refresh_token { "fake-refresh-token" }

    status { "copying_planning" }
  end
end
