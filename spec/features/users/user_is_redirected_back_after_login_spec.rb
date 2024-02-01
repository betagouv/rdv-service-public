require "rails_helper"

RSpec.describe "User is redirected back to requested page after login" do
  let!(:user) { create(:user) }

  it "works" do
    visit "/users/rdvs"
    expect(page).to have_current_path("/users/sign_in")
    expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")

    fill_in("user_email", with: user.email)
    fill_in("password", with: user.password)
    click_button("Se connecter")
    expect(page).to have_current_path("/users/rdvs")
  end

  context "when visiting a very very long URL" do
    it "reports ActionDispatch::Cookies::CookieOverflow to Sentry" do
      long_path = "/users/rdvs?bogus_param=#{'coucou' * 1000}"
      expect do
        visit long_path
      end.to raise_error(ActionDispatch::Cookies::CookieOverflow)

      expect(sentry_events.last.exception.values.first.type).to eq("ActionDispatch::Cookies::CookieOverflow")
      expect(sentry_events.last.contexts["path"][:original_fullpath]).to eq(long_path)
    end
  end
end
