# frozen_string_literal: true

describe "api/v2/organisations requests", type: :request do
  let!(:agent) { create(:agent) }

  describe "GET api/v2/organisations" do
    subject { get api_v2_organisations_path, headers: api_auth_headers_for_agent(agent) }

    context "no existing organisations" do
      it "returns empty array" do
        subject
        expect(response.status).to eq(200)
        expect(parsed_response_body).to eq([])
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
        expect(parsed_response_body.count).to eq(2)
        expect(parsed_response_body.pluck("id")).to \
          contain_exactly(organisation1.id, organisation2.id)
      end
    end

    context "when geolocalisation parameters are passed" do
      subject do
        get api_v2_organisations_path(departement_number: departement_number, city_code: city_code),
            headers: api_auth_headers_for_agent(agent)
      end

      let!(:organisation1) { create(:organisation) }
      let!(:organisation2) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }
      let(:departement_number) { "26" }
      let!(:city_code) { "26323" }
      let(:geo_search) do
        instance_double(Users::GeoSearch, most_relevant_organisations: Organisation.where(id: organisation2.id))
      end

      before do
        allow(Users::GeoSearch).to receive(:new)
          .with(departement: departement_number, city_code: city_code, street_ban_id: nil)
          .and_return(geo_search)
      end

      it "returns the organisations attributed to the sector" do
        subject
        expect(response.status).to eq(200)
        expect(parsed_response_body.count).to eq(1)
        expect(parsed_response_body.pluck("id")).to \
          contain_exactly(organisation2.id)
      end
    end
  end
end
