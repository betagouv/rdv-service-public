RSpec.describe "Admin::RdvCollectifs", type: :request do
  include Rails.application.routes.url_helpers

  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, :collectif, organisation:) }

  describe "PUT /admin/organisations/:organisation_id/rdvs_collectifs/:id" do
    context "quand l'agent vient de la sélection de créneaux avec un usager en contexte" do
      it "redirige vers la page de créneaux et affiche un flash avec le motif et la date" do
        organisation = create(:organisation)
        motif = create(:motif, :collectif, organisation:, name: "Atelier Collectif")
        lieu = create(:lieu, organisation:)
        agent = create(:agent, admin_role_in_organisations: [organisation])
        user = create(:user, organisations: [organisation])
        rdv = create(:rdv, motif:, organisation:, agents: [agent], users: [user], lieu:)
        creneaux_search_url = admin_organisation_creneaux_search_selection_creneaux_url(organisation, user_ids: [user.id], motif_id: motif.id, lieu_ids: [lieu.id])
        sign_in agent

        get edit_admin_organisation_rdvs_collectif_path(organisation, rdv),
            headers: { "HTTP_REFERER" => creneaux_search_url }
        form_id = Nokogiri::HTML(response.body).at_css("input[name='return_to_form_id']")&.[]("value")
        put admin_organisation_rdvs_collectif_path(organisation, rdv),
            params: { rdv: { user_ids: [user.id] }, return_to_form_id: form_id }

        expect(response).to redirect_to(creneaux_search_url)
        follow_redirect!
        expect(response.body).to include("Participants mis à jour - Atelier Collectif du")
      end
    end

    context "quand l'agent vient de la sélection de créneaux sans usager en contexte" do
      it "redirige vers la page d'édition et affiche le flash standard" do
        organisation = create(:organisation)
        motif = create(:motif, :collectif, organisation:)
        agent = create(:agent, admin_role_in_organisations: [organisation])
        user = create(:user, organisations: [organisation])
        rdv = create(:rdv, motif:, organisation:, agents: [agent], users: [user])
        creneaux_search_url = admin_organisation_creneaux_search_selection_creneaux_url(organisation, motif_id: motif.id)
        sign_in agent

        get edit_admin_organisation_rdvs_collectif_path(organisation, rdv),
            headers: { "HTTP_REFERER" => creneaux_search_url }
        put admin_organisation_rdvs_collectif_path(organisation, rdv),
            params: { rdv: { user_ids: [user.id] } }

        expect(response).to redirect_to(edit_admin_organisation_rdvs_collectif_path(organisation, rdv))
        follow_redirect!
        expect(response.body).to include("Participants mis à jour")
      end
    end

    context "quand l'agent vient d'une autre page" do
      it "redirige vers la page d'édition" do
        organisation = create(:organisation)
        motif = create(:motif, :collectif, organisation:)
        agent = create(:agent, admin_role_in_organisations: [organisation])
        user = create(:user, organisations: [organisation])
        rdv = create(:rdv, motif:, organisation:, agents: [agent], users: [user])
        sign_in agent

        get edit_admin_organisation_rdvs_collectif_path(organisation, rdv),
            headers: { "HTTP_REFERER" => admin_organisation_rdvs_collectifs_url(organisation) }
        put admin_organisation_rdvs_collectif_path(organisation, rdv),
            params: { rdv: { user_ids: [user.id] } }

        expect(response).to redirect_to(edit_admin_organisation_rdvs_collectif_path(organisation, rdv))
      end
    end

    context "sans visite préalable de la page d'édition" do
      it "redirige vers la page d'édition" do
        organisation = create(:organisation)
        motif = create(:motif, :collectif, organisation:)
        agent = create(:agent, admin_role_in_organisations: [organisation])
        user = create(:user, organisations: [organisation])
        rdv = create(:rdv, motif:, organisation:, agents: [agent], users: [user])
        sign_in agent

        put admin_organisation_rdvs_collectif_path(organisation, rdv),
            params: { rdv: { user_ids: [user.id] } }

        expect(response).to redirect_to(edit_admin_organisation_rdvs_collectif_path(organisation, rdv))
      end
    end
  end

  describe "GET /admin/organisations/:organisation_id/rdv_collectifs" do
    it "is successful" do
      agent = create(:agent, admin_role_in_organisations: [organisation])
      create(:rdv, motif: motif, organisation: organisation, agents: [agent])
      sign_in agent

      get admin_organisation_rdvs_collectifs_path(organisation)

      expect(response).to be_successful
    end

    it "render index template" do
      agent = create(:agent, admin_role_in_organisations: [organisation])
      create(:rdv, motif: motif, organisation: organisation, agents: [agent])
      sign_in agent

      get admin_organisation_rdvs_collectifs_path(organisation)

      expect(response).to render_template(:index)
    end

    it "show delete collective rdv icon" do
      agent = create(:agent, admin_role_in_organisations: [organisation])
      create(:rdv, motif: motif, organisation: organisation, agents: [agent])
      sign_in agent

      get admin_organisation_rdvs_collectifs_path(organisation)

      expect(response.body).to include("Confirmez-vous la suppression de ce rendez-vous collectif ?")
    end

    context "with an basic role in organisation agent" do
      it "dont show delete collective rdv icon" do
        agent = create(:agent, basic_role_in_organisations: [organisation])
        create(:rdv, motif: motif, organisation: organisation, agents: [agent])
        sign_in agent

        get admin_organisation_rdvs_collectifs_path(organisation)

        expect(response.body).not_to include("Confirmez-vous la suppression de ce rendez-vous collectif ?")
      end
    end
  end
end
