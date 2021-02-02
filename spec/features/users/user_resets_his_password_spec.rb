feature "User resets his password spec" do
  context "through password reset page" do
    before { visit new_agent_password_path }

    scenario "sees proper translation of links" do
      expect(page).to have_content("Mot de passe oublié ?")
      expect(page).to have_link("Se connecter")
    end
  end
end
