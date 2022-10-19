# frozen_string_literal: true

RSpec.describe "Admin::RdvCollectifs", type: :request do
  include Rails.application.routes.url_helpers

  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, :collectif) }

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
