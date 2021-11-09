# frozen_string_literal: true

describe "api/v1/motifs requests", type: :request do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }

  describe "GET api/v1/:organisation_id/motifs" do
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

    context "filtered on active" do
      let!(:deleted_at) { Time.zone.yesterday.noon }
      let!(:motif1) { create(:motif, organisation: organisation, service: service) }
      let!(:motif2) { create(:motif, organisation: organisation, service: service, deleted_at: deleted_at) }

      context "when retrieving active motifs only" do
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

      context "when retrieving inactive motifs" do
        it "returns the inactive motifs" do
          get(
            api_v1_organisation_motifs_path(organisation),
            headers: api_auth_headers_for_agent(agent),
            params: { active: false }
          )
          expect(response.status).to eq(200)
          response_parsed = JSON.parse(response.body)
          expect(response_parsed["motifs"].pluck("id")).to contain_exactly(motif2.id)
          expect(response_parsed["motifs"].pluck("deleted_at")).to contain_exactly(deleted_at.to_s)
        end
      end
    end

    context "filtered on reservable online" do
      let!(:motif1) { create(:motif, organisation: organisation, service: service, reservable_online: true) }
      let!(:motif2) { create(:motif, organisation: organisation, service: service, reservable_online: false) }

      context "when retrieving reservable online motifs only" do
        it "returns the reservable online motifs" do
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

      context "when retrieving non reservable online motifs" do
        it "returns the non reservable online motifs" do
          get(
            api_v1_organisation_motifs_path(organisation),
            headers: api_auth_headers_for_agent(agent),
            params: { reservable_online: false }
          )
          expect(response.status).to eq(200)
          response_parsed = JSON.parse(response.body)
          expect(response_parsed["motifs"].pluck("id")).to contain_exactly(motif2.id)
          expect(response_parsed["motifs"].pluck("reservable_online")).to contain_exactly(false)
        end
      end
    end

    context "filtered on service" do
      let!(:agent) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }
      let!(:another_service) { create(:service) }

      let!(:motif1) { create(:motif, organisation: organisation, service: service) }
      let!(:motif2) { create(:motif, organisation: organisation, service: another_service) }

      it "returns the service specific motifs" do
        get(
          api_v1_organisation_motifs_path(organisation),
          headers: api_auth_headers_for_agent(agent),
          params: { service_id: service.id }
        )
        expect(response.status).to eq(200)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["motifs"].pluck("id")).to contain_exactly(motif1.id)
      end
    end
  end
end
