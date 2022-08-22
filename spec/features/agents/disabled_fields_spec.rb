require "rails_helper"

RSpec.describe "some fields that are specific to a certain domain can be disabled and hidden from the interface" do
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let(:territory) do
    create(:territory, enable_affiliation_number_field: true)
  end

  before do
    login_as(agent, scope: :agent)
    user.update(affiliation_number: "numero_affiliation_123")
  end

  it "shows the restricted fields only if they are enabled" do
    visit admin_organisation_user_path(organisation, user)

    # It shows the
    expect(page).to have_content("numero_affiliation_123", count: 2)
  end
end
