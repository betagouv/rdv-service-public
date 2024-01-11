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

  it "raises an error when our application key is about to expire" do
    application_key_expiration_date = Date.new(2025, 1, 10)
    key_refresh_url = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/ad7b4a46-0051-47b6-bf31-713aa849e5d4/isMSAApp~/true"

    if 2.months.from_now > application_key_expiration_date
      raise <<~ERROR
        Le secret de client de l'application d'oauth Microsoft expire dans moins de 2 mois.
        Pour que la synchro Outlook continue de fonctionner, vous générez un nouveau secret via #{key_refresh_url}
      ERROR
    end
  end
end
