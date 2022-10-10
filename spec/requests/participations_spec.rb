# frozen_string_literal: true

RSpec.describe "Participations", type: :request do
  let(:service) { create(:service) }
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
  let(:motif) { create(:motif, :collectif, organisation: organisation, service: service) }
  let(:rdv) { create(:rdv, organisation: organisation, motif: motif, agents: [agent]) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user, :with_no_email, :with_no_phone_number) }

  before do
    login_as(agent, scope: :agent)
    rdv.rdvs_users.create(user: user1)
    rdv.rdvs_users.create(user: user2)
  end

  describe "update" do
    it "returns http redirect and notif" do
      put(
        admin_organisation_rdv_participation_path(rdv.organisation, rdv, rdv.rdvs_users.first),
        params: { rdvs_user: { status: "seen" } }
      )
      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to eq("Status de participation pour #{rdv.rdvs_users.first.user.full_name} mis à jour")
    end
  end

  describe "destroy" do
    it "returns http redirect and notif" do
      delete(
        admin_organisation_rdv_participation_path(rdv.organisation, rdv, rdv.rdvs_users.first)
      )
      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to eq("La participation de l'usager au rdv a été supprimée.")
    end
  end
end
