# frozen_string_literal: true

describe "api/v1/motifs requests", type: :request do
  describe "GET api/v1/:organisation_id/motifs" do
    let!(:organisation) { create(:organisation) }
    let!(:service) { create(:service) }
    let!(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }

    context "when the agent does not belong to the organisation" do
      let!(:other_orga) { create(:organisation) }
      let!(:motif) { create(:motif, organisation: other_orga, service: service) }

      it "does not return the motifs list" do
        get api_v1_organisation_motifs_path(other_orga), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["motifs"]).to eq([])
      end
    end

    context "when the agent belongs to multiple organisations" do
      let!(:motif1) { create(:motif, organisation: organisation, service: service) }
      let!(:organisation2) { create(:organisation) }
      let!(:motif2) { create(:motif, organisation: organisation2, service: service) }
      let!(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation, organisation2]) }

      it "returns the organisation motifs only" do
        get api_v1_organisation_motifs_path(organisation), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["motifs"].pluck("id")).to contain_exactly(motif1.id)
      end
    end

    context "when retrieving active motifs only" do
      let!(:motif1) { create(:motif, organisation: organisation, service: service) }
      let!(:motif2) { create(:motif, organisation: organisation, service: service, deleted_at: Date.yesterday) }

      it "returns the active motifs" do
        get(
          api_v1_organisation_motifs_path(organisation),
          headers: api_auth_headers_for_agent(agent),
          params: { active: true }
        )
        expect(response.status).to eq(200)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["motifs"].pluck("id")).to contain_exactly(motif1.id)
      end
    end

    context "when retrieving reservable online motifs only" do
      let!(:motif1) { create(:motif, organisation: organisation, service: service, reservable_online: true) }
      let!(:motif2) { create(:motif, organisation: organisation, service: service, reservable_online: false) }

      it "returns the active motifs" do
        get(
          api_v1_organisation_motifs_path(organisation),
          headers: api_auth_headers_for_agent(agent),
          params: { reservable_online: true }
        )
        expect(response.status).to eq(200)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["motifs"].pluck("id")).to contain_exactly(motif1.id)
      end
    end
  end
end
