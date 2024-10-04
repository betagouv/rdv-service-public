RSpec.describe "rdv-insertion API: users" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation_rdv_insertion]) }
  let(:user) { create(:user, organisations: [organisation_rdv_insertion, other_organisation_rdv_insertion, organisation_rdv_solidarites]) }

  let(:shared_secret) { "S3cr3T" }
  let(:auth_headers) { api_auth_headers_with_shared_secret(agent, shared_secret) }

  let(:organisation_rdv_insertion) { create(:organisation, verticale: "rdv_insertion") }
  let(:other_organisation_rdv_insertion) { create(:organisation, verticale: "rdv_insertion") }
  let(:organisation_rdv_solidarites) { create(:organisation, verticale: "rdv_solidarites") }

  before do
    allow(ENV).to receive(:fetch).with("SHARED_SECRET_FOR_AGENTS_AUTH").and_return(shared_secret)
  end

  it "returns the user along with the rdv_insertion related user_profiles" do
    get api_rdvinsertion_user_path(user.id), headers: auth_headers
    expect(response.status).to eq(200)
    response_user_profiles = response.parsed_body.dig("user", "user_profiles")
    response_organisation_ids = response_user_profiles.map { |user_profile| user_profile.dig("organisation", "id") }
    expect(response_organisation_ids).to contain_exactly(organisation_rdv_insertion.id, other_organisation_rdv_insertion.id)
  end
end
