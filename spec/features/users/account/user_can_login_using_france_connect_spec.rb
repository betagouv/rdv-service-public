RSpec.describe "User can login using FranceConnect" do
  stub_env_with(
    FRANCECONNECT_V2_BASE_URL: "https://fcp-low.sbx.dev-franceconnect.fr/api/v2",
    FRANCECONNECT_V2_CLIENT_ID: "fake_france_connect_v2_client_id",
    FRANCECONNECT_V2_CLIENT_SECRET: "fake_france_connect_v2_client_secret"
  )

  context "visiting rdv-solidarites domain" do
    it "allows a user to create an account using the FranceConnect button" do
      visit "http://www.rdv-solidarites-test.localhost/users/sign_in"
      expect(page).to have_link(href: "/franceconnect_v2/auth")
    end
  end

  context "visiting rdv-aide-numerique domain" do
    it "hides the FranceConnect button" do
      visit "http://www.rdv-aide-numerique-test.localhost/users/sign_in"
      expect(page).not_to have_link("S'identifier avec FranceConnect")
    end
  end
end
