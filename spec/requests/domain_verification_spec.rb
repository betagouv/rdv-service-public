# see https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-configure-publisher-domain
RSpec.describe "Microsoft domain verification" do
  stub_env_with(AZURE_APPLICATION_CLIENT_ID: "public_client_id_123456")

  it "shows the public app id at the correct route" do
    get "/.well-known/microsoft-identity-association.json"
    parsed_response = response.parsed_body
    expect(parsed_response.dig("associatedApplications", 0, "applicationId")).to eq "public_client_id_123456"
  end
end
