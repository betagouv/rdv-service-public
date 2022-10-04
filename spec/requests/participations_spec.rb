# frozen_string_literal: true

RSpec.describe "Participations", type: :request do
  let(:service) { create(:service) }
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let(:motif) { create(:motif, :collectif) }
  let(:rdv) { create(:rdv, organisation: organisation, motif: motif) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user, :with_no_email, :with_no_phone_number) }

  before do
    login_as(agent, scope: :agent)
    rdv.rdvs_users.create(user: user1)
    rdv.rdvs_users.create(user: user2)
  end

  describe "update" do
    it "returns http success" do
      expect(response).to have_http_status(:success)
    end
  end

  describe "destroy" do
    it "returns http success" do
      delete admin_organisation_rdv_participation_path(rdv.organisation, rdv, rdv.rdvs_users.first)
      p response
      expect(response).to have_http_status(:success)
    end
  end
end
