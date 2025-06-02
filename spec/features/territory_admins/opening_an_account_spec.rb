RSpec.describe "Un agent peut créer un territoire, en faisant vérifier son compte soit par notre équipe soit via une appli OAuth" do
  let(:application) do
    create(:oauth_application, name: "Mon Suivi Social", default_service: create(:service, name: "Action Sociale"))
  end

  context "quand l'agent a déjà été créé via une connexion ProConnect" do
    let(:agent) { create(:agent, :no_services, email: "francis@factice.org", proconnect_siret: "13002526500013") }

    before do
      AnnuaireServicePublicStubs.stub_siret_as_anct(agent.proconnect_siret, self)
    end

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

    context "mais que son compte n'est pas vérifié par une application partenaire" do
      let(:super_admin) { create :super_admin }

      let!(:service) { create(:service, name: "Service social") }

      around { |example| perform_enqueued_jobs { example.run } }

      it "permet de demander une ouverture d'espace" do
        visit "/admin/organisations/configuration" # Les pages de paramètres des applications externes mènent à cette url
        click_on "Demander à ouvrir un espace"

        fill_in("Nom de l’espace", with: "Commune de Montreuil")
        fill_in("Nom de votre première organisation", with: "CCAS de Montreuil")
        fill_in("Pour quel service souhaitez-vous gérer des rendez-vous ?", with: "Action Sociale")
        click_on "Envoyer la demande"

        expect(page).to have_content("Votre demande a bien été enregistrée. Notre équipe va l'étudier et revenir vers vous dans les meilleurs délais")

        login_as(super_admin, scope: :super_admin)

        visit super_admins_territory_creation_requests_url(host: "http://www.rdv-mairie-test.localhost")
        click_on "Commune de Montreuil"

        expect(page).to have_content("Demande d'ouverture d'espace")

        click_on "Accepter"

        select "Commune", from: "Catégorie de l'espace"

        select "Service social", from: "Service"
        click_on "Enregistrer"
        expect(page).to have_content "Le nouvel espace a été créé"

        expect(Territory.last).to have_attributes(
          name: "Commune de Montreuil",
          admin_agents: [agent]
        )

        expect(Organisation.last).to have_attributes(
          name: "CCAS de Montreuil",
          agents: [agent]
        )

        open_email(agent.email)
        expect(current_email.subject).to eq "Votre espace RDV Service Public est ouvert 🚀"

        visit super_admins_territory_creation_requests_url(host: "http://www.rdv-mairie-test.localhost")

        expect(page).to have_content "Il n'y a aucune demande avec ce statut"

        click_on("Demandes acceptées")

        expect(page).to have_content "Commune de Montreuil"
      end

      context "quand il y a un doublon probable" do
        let(:duplicate_organisation) { create(:organisation, name: "Mairie de Montreuil") }
        let(:territory_creation_request) do
          create(:territory_creation_request, agent: agent, territory_name: "Commune de Montreuil", organisation_name: "CCAS de Montreuil")
        end

        before { login_as(super_admin, scope: :super_admin) }

        context "via l'adresse mail d'autres agents" do
          let!(:agent_with_same_email_domain) { create(:agent, email: "regis@factice.org", basic_role_in_organisations: [duplicate_organisation]) }

          it "affiche la liste des organisations potentiellement en doublon" do
            visit edit_super_admins_territory_creation_request_path(territory_creation_request.id)
            expect(page).to have_content("Attention, ces organisations ont des agents avec des adresses email similaires")
            expect(page).to have_content("Mairie de Montreuil")
          end
        end

        context "via le siret d'autres agents" do
          let!(:agent_with_same_siret) { create(:agent, proconnect_siret: "13002526500013", basic_role_in_organisations: [duplicate_organisation]) }

          it "affiche la liste de organisations potentiellement en doublon" do
            visit edit_super_admins_territory_creation_request_path(territory_creation_request.id)
            expect(page).to have_content("Attention, ces organisations ont des agents avec le même SIRET")
            expect(page).to have_content("Mairie de Montreuil")
          end
        end
      end
    end
  end
end
