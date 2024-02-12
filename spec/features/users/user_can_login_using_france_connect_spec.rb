RSpec.describe "User can login using FranceConnect" do
  before do
    mock_france_connect_profile = {
      sub: "12345",
      email: "france@monopolis.fr",
      given_name: "France",
      family_name: "Gall",
      birthdate: "1947-10-09",
    }
    OmniAuth.config.add_mock(:franceconnect, info: mock_france_connect_profile)
  end

  after do
    OmniAuth.config.mock_auth[:franceconnect] = nil
  end

  context "visiting rdv-solidarites domain" do
    it "allows a user to create an account using the FranceConnect button" do
      visit "http://www.rdv-solidarites-test.localhost/users/sign_in"
      expect(page).to have_link("S'identifier avec FranceConnect")

      expect { click_on "S'identifier avec FranceConnect" }.to change(User, :count).by(1)

      expect(User.last).to have_attributes(
        email: "france@monopolis.fr",
        first_name: "France",
        last_name: "Gall",
        franceconnect_openid_sub: "12345",
        birth_date: Date.new(1947, 10, 9)
      )

      expect(page).to have_current_path("/users/rdvs")
      expect(page).to have_link("Déconnexion")
    end
  end

  context "visiting rdv-aide-numerique domain" do
    it "hides the FranceConnect button" do
      visit "http://www.rdv-aide-numerique-test.localhost/users/sign_in"
      expect(page).not_to have_link("S'identifier avec FranceConnect")
    end
  end
end
