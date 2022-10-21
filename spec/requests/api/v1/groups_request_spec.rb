# frozen_string_literal: true

describe "api/v1/groups requests", type: :request do
  it "returns the territories as groups" do
    create(:territory)

    get api_v1_groups_path
    expect(response).to have_http_status(:ok)
    expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(Territory.all))
  end

  context "when there is no territory" do
    it "returns an empty list" do
      get api_v1_groups_path
      expect(response).to have_http_status(:ok)
      expect(parsed_response_body[:groups]).to match([])
    end
  end

  context "when there is a lot of territories" do
    it "returns a paginated list" do
      page1 = create_list(:territory, 2)
      page2 = create_list(:territory, 2)
      page3 = create_list(:territory, 1)

      get api_v1_groups_path, params: { page: 0, per: 2 }
      expect(parsed_response_body[:meta]).to match(current_page: 1, next_page: 2, prev_page: nil, total_count: 5, total_pages: 3)
      expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(page1))

      get api_v1_groups_path, params: { page: 1, per: 2 }
      expect(parsed_response_body[:meta]).to match(current_page: 1, next_page: 2, prev_page: nil, total_count: 5, total_pages: 3)
      expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(page1))

      get api_v1_groups_path, params: { page: 2, per: 2 }
      expect(parsed_response_body[:meta]).to match(current_page: 2, next_page: 3, prev_page: 1, total_count: 5, total_pages: 3)
      expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(page2))

      get api_v1_groups_path, params: { page: 3, per: 2 }
      expect(parsed_response_body[:meta]).to match(current_page: 3, next_page: nil, prev_page: 2, total_count: 5, total_pages: 3)
      expect(parsed_response_body[:groups]).to match(GroupBlueprint.render_as_hash(page3))
    end
  end
end
