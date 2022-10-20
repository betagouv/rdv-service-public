# frozen_string_literal: true

describe "api/v2/organizations requests", type: :request do
  it "returns the organisations as organizations" do
    create(:organisation)

    get api_v2_organizations_path
    expect(response).to have_http_status(:ok)
    expect(parsed_response_body).to match(OrganizationBlueprint.render_as_hash(Organisation.all))
  end

  it "filters on a given territory when the group id is provided" do
    matching = create(:organisation)
    unmatching = create(:organisation)

    get api_v2_organizations_path, params: { group_id: matching.territory_id }
    expect(response).to have_http_status(:ok)
    expect(parsed_response_body).to include(OrganizationBlueprint.render_as_hash(matching))
    expect(parsed_response_body).not_to include(OrganizationBlueprint.render_as_hash(unmatching))
  end

  context "when there is no organization" do
    it "returns an empty list" do
      get api_v2_organizations_path
      expect(response).to have_http_status(:ok)
      expect(parsed_response_body).to match([])
    end
  end

  context "when there is a lot of organizations" do
    it "returns a paginated list" do
      page1 = create_list(:organisation, 2)
      page2 = create_list(:organisation, 2)
      page3 = create_list(:organisation, 1)

      get api_v2_organizations_path, params: { page: 0, per: 2 }
      expect(response).to be_paginated(current_page: 1, next_page: 2, prev_page: nil, total_count: 5, total_pages: 3)
      expect(parsed_response_body).to match(OrganizationBlueprint.render_as_hash(page1))

      get api_v2_organizations_path, params: { page: 1, per: 2 }
      expect(response).to be_paginated(current_page: 1, next_page: 2, prev_page: nil, total_count: 5, total_pages: 3)
      expect(parsed_response_body).to match(OrganizationBlueprint.render_as_hash(page1))

      get api_v2_organizations_path, params: { page: 2, per: 2 }
      expect(response).to be_paginated(current_page: 2, next_page: 3, prev_page: 1, total_count: 5, total_pages: 3)
      expect(parsed_response_body).to match(OrganizationBlueprint.render_as_hash(page2))

      get api_v2_organizations_path, params: { page: 3, per: 2 }
      expect(response).to be_paginated(current_page: 3, next_page: nil, prev_page: 2, total_count: 5, total_pages: 3)
      expect(parsed_response_body).to match(OrganizationBlueprint.render_as_hash(page3))
    end
  end
end
