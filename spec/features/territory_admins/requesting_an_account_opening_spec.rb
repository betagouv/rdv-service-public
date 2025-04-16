RSpec.describe "Un agent non vérifié via une application externe peut créer un territoire" do
  let(:application) do
    create(:oauth_application, name: "Mon Suivi Social", default_service: create(:service, name: "Action Sociale"))
  end

  context "quand l'agent a déjà été créé via une connexion ProConnect" do
    let(:agent) { create(:agent, :no_services) }

    before { login_as(agent, scope: :agent) }

    context "et qu'il s'est connecté via une application externe" do
      let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }

      it "permet de créer un territoire et une organisation" do
        visit "/admin/organisations/configuration" # Les pages de paramètres des applications externes mènent à cette url

        click_on "Ouvrir un espace"

        fill_in("Nom de votre organisation", with: "CCAS de Montreuil")
        fill_in("Nom du territoire", with: "Commune de Montreuil")
        click_on "Enregistrer"

        expect(page).to have_content "Configuration"
        expect(agent.reload.organisations.last.name).to eq "CCAS de Montreuil"
      end
    end

    context "mais que son compte n'est pas vérifié par une organisation externe" do
      it "ne permet pas de créer un territoire" do
        visit "/admin/organisations/configuration" # Les pages de paramètres des applications externes mènent à cette url
        expect(page).to have_content "Rencontrer notre équipe"
        expect(page).not_to have_content "Ouvrir un espace"
      end
    end
  end
end
