RSpec.describe "Agent can edit user" do
  let!(:organisation) { create(:organisation, name: "MDS des Champs") }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Jean", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  around { |example| perform_enqueued_jobs { example.run } }

  before do
    login_as(agent, scope: :agent)
    visit "http://www.rdv-aide-numerique-test.localhost/"
    click_link "Usagers"
    click_link "Créer un usager", match: :first
    expect_page_title("Nouvel usager")
  end

  context "the organisation has "

end
