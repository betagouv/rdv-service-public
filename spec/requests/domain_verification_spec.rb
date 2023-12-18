# see https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-configure-publisher-domain
RSpec.describe "Microsoft domain verification" do
  it "shows the public app id of the current domain at the correct route" do
    allow(Domain::RDV_SOLIDARITES).to receive(:azure_application_client_id).and_return("public_client_id_123456")
    get "/.well-known/microsoft-identity-association.json"
    parsed_response = JSON.parse(response.body)
    expect(parsed_response.dig("associatedApplications", 0, "applicationId")).to eq "public_client_id_123456"
  end
end
