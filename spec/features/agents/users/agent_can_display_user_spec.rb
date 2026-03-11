RSpec.describe "Agent can display user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit admin_organisation_user_path(organisation, user)
  end

  context "when user is unregistered but has logged through FranceConnect" do
    let!(:user) { create(:user, latest_login_at: nil, logged_once_with_franceconnect: true, organisations: [organisation]) }

    it "displays a message to inform of FranceConnect binding, and hides the invitation prompt" do
      expect(page).to have_content("Cet usager s'est déjà connecté via FranceConnect.")
      expect(page).not_to have_content("Cet usager ne s'est pas encore créé de compte")
    end
  end

  context "when the user has an external reference" do
    let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
    let!(:user) { create(:user, organisations: [organisation]) }
    let(:application) { create(:oauth_application, name: "Démarches Simplifiées") }
    let!(:external_reference) do
      create(:external_reference, oauth_application: application, territory: organisation.territory, item: user)
    end

    it "shows a link to the external reference" do
      visit admin_organisation_user_path(organisation, user)
      expect(page).to have_content("Voir sur Démarches Simplifiées")
    end

    context "quand l'agent peut voir l'usager, mais qu'il n'a pas fait de connexion oauth explicite (ça arrive pour les migrations de Conums pour les agents qui sont invités automatiquement)" do
      let!(:oauth_token) { nil }

      it "shows a link to the external reference" do
        visit admin_organisation_user_path(organisation, user)
        expect(page).to have_content("Voir sur Démarches Simplifiées")
      end
    end
  end
end
