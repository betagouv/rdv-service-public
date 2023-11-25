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
    create(:participation, user: user1, rdv: rdv)
    create(:participation, user: user2, rdv: rdv)
  end

  describe "update" do
    it "returns status ok on remote put" do
      put(
        admin_organisation_rdv_participation_path(rdv.organisation, rdv, rdv.participations.first),
        xhr: true,
        params: { participation: { status: "seen" } }
      )
      expect(response).to have_http_status(:success)
    end
  end

  describe "destroy" do
    it "returns http redirect and notif" do
      delete(
        admin_organisation_rdv_participation_path(rdv.organisation, rdv, rdv.participations.first)
      )
      expect(response).to redirect_to(admin_organisation_rdv_path(organisation, rdv))
      expect(flash[:notice]).to eq("La participation de l'usager au rdv a été supprimée.")
    end
  end
end
