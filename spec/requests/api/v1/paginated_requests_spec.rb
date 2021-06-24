# frozen_string_literal: true

describe "paginated requests", type: :request do
  let(:agent) { create(:agent) }

  before do
    create_list(:agent_role, 210, agent: agent) # This also creates 210 new organisations
    subject
  end

  describe "default pagination" do
    subject { get api_v1_organisations_path, headers: api_auth_headers_for_agent(agent) }

    it do
      expect(response.status).to eq(200)
      result = JSON.parse(response.body)
      expect(result["organisations"].count).to eq(100)
      expect(result["meta"]).to eq({ "current_page" => 1, "next_page" => 2, "prev_page" => nil, "total_count" => 210, "total_pages" => 3 })
    end
  end

  describe "specified pagination params" do
    subject { get api_v1_organisations_path(page: 2, per: 10), headers: api_auth_headers_for_agent(agent) }

    it do
      expect(response.status).to eq(200)
      result = JSON.parse(response.body)
      expect(result["organisations"].count).to eq(10)
      expect(result["meta"]).to eq({ "current_page" => 2, "next_page" => 3, "prev_page" => 1, "total_count" => 210, "total_pages" => 21 })
    end
  end
end
