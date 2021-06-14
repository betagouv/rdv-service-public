# frozen_string_literal: true

describe "api/v1/organisations requests", type: :request do
  let!(:agent) { create(:agent) }

  describe "GET api/v1/organisations" do
    subject { get api_v1_organisations_path, headers: api_auth_headers_for_agent(agent) }

    context "no existing organisations" do
      it "returns empty array" do
        subject
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result["organisations"]).to eq([])
      end
    end

    context "some existing organisations" do
      let!(:organisation1) { create(:organisation) }
      let!(:organisation2) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }
      let!(:other_organisation) { create(:organisation) }
      let!(:other_agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }

      it "returns policy scoped organisations" do
        subject
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result["organisations"].count).to eq(2)
        expect(result["organisations"].pluck("id")).to \
          contain_exactly(organisation1.id, organisation2.id)
      end
    end
  end
end
