# frozen_string_literal: true

# see https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-configure-publisher-domain
RSpec.describe "Microsoft domain verification" do
  around do |example|
    previous_client_id = ENV["AZURE_APPLICATION_CLIENT_ID"]
    ENV["AZURE_APPLICATION_CLIENT_ID"] = "public_client_id_123456"

    example.run

    ENV["AZURE_APPLICATION_CLIENT_ID"] = previous_client_id
  end

  it "shows the public app id at the correct route" do
    get "/.well-known/microsoft-identity-association.json"
    parsed_response = JSON.parse(response.body)
    expect(parsed_response.dig("associatedApplications", 0, "applicationId")).to eq "public_client_id_123456"
  end
end
