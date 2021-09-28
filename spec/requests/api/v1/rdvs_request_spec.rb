# frozen_string_literal: true

describe "api/v1/rdvs requests", type: :request do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:motif) { create(:motif, service: service) }
  let!(:rdv) { create(:rdv, organisation: organisation, motif: motif) }

  describe "GET api/v1/organisations/:id/rdvs" do
    context "multiple organisations and motifs" do
      let!(:organisation2) { create(:organisation) }
      let!(:rdv2) { create(:rdv, organisation: organisation2, motif: motif) }
      let!(:service2) { create(:service) }
      let!(:motif2) { create(:motif, service: service2) }
      let!(:rdv3) { create(:rdv, organisation: organisation, motif: motif2) }

      context "basic role" do
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }

        it "returns policy scoped rdvs" do
          get api_v1_organisation_rdvs_path(organisation), headers: api_auth_headers_for_agent(agent)
          expect(response.status).to eq(200)
          response_parsed = JSON.parse(response.body)
          expect(response_parsed["rdvs"].pluck("id")).to contain_exactly(rdv.id)
        end
      end

      context "admin role" do
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }

        it "returns policy scoped rdvs" do
          get api_v1_organisation_rdvs_path(organisation), headers: api_auth_headers_for_agent(agent)
          expect(response.status).to eq(200)
          response_parsed = JSON.parse(response.body)
          expect(response_parsed["rdvs"].pluck("id")).to contain_exactly(rdv.id, rdv3.id)
        end
      end
    end
  end
end
