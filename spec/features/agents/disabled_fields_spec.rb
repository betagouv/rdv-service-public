RSpec.describe "some fields that are specific to a certain domain can be disabled and hidden from the interface", versioning: true do
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let(:territory) do
    create(:territory, enable_affiliation_number_field: true)
  end

  before do
    login_as(agent, scope: :agent)
    user.update(affiliation_number: "numero_affiliation_123") # Pour créer une version Papertail
  end

  it "shows the restricted fields only if they are enabled", js: true do
    visit admin_organisation_user_path(organisation, user)

    expect(page).to have_content("Numéro d'allocataire : numero_affiliation_123")

    click_button("Historique des changements")
    expect(page).to have_content("numero_affiliation_123", count: 2)

    territory.update!(enable_affiliation_number_field: false)

    visit admin_organisation_user_path(organisation, user)
    click_button("Historique des changements")
    expect(page).not_to have_content("numero_affiliation_123")
  end
end
