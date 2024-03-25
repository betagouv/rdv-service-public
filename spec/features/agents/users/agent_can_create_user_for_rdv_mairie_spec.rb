RSpec.describe "Agent can create user" do
  include_context "rdv_mairie_api_authentication"

  let!(:organisation) { create(:organisation, name: "Mairie de Romainville") }
  let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:ants_pre_demande_number) { "1122334455" }

  before do
    create(:motif, name: "Carte d'identité", organisation: organisation, restriction_for_rdv: nil, motif_category: cni_motif_category, default_duration_in_min: 25)
  end

  before do
    login_as(agent, scope: :agent)
    visit "http://www.rdv-mairie-test.localhost/"
    click_link "Usagers"
    click_link "Créer un usager", match: :first
    expect_page_title("Nouvel usager")
  end

end
