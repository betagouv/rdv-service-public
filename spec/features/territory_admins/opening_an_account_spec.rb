RSpec.describe "Un agent peut créer un territoire, en faisant vérifier son compte soit par notre équipe soit via une appli OAuth" do
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
      let(:super_admin) { create :super_admin }

      let!(:service) { create(:service, name: "Service social") }

      it "ne permet pas de créer un territoire" do
        visit "/admin/organisations/configuration" # Les pages de paramètres des applications externes mènent à cette url
        click_on "Demander à ouvrir un espace"

        fill_in("Nom de l'espace", with: "Commune de Montreuil")
        fill_in("Nom de votre première organisation", with: "CCAS de Montreuil")
        fill_in("Pour quel service souhaitez-vous gérer des rendez-vous ?", with: "Action Sociale")
        click_on "Envoyer la demande"

        expect(page).to have_content("Votre demande a bien été enregistrée. Notre équipe va l'étudier et revenir vers vous dans les meilleurs délais")

        login_as(super_admin, scope: :super_admin)

        visit super_admins_territory_creation_requests_path
        click_on "Commune de Montreuil"

        expect(page).to have_content("Demande d'ouverture d'espace")

        select "Service social", from: "Services"

        click_on "Ouvrir le compte"
        expect(page).to have_content "coucou"
      end
    end
  end
end
