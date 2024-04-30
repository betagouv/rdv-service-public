RSpec.describe "User can update their information" do
  let!(:organisation) { create(:organisation, territory: territory) }
  let(:user) { create(:user, organisations: [organisation]) }

  let(:territory) do
    create(:territory, enable_caisse_affiliation_field: true,
                       enable_affiliation_number_field: true, enable_number_of_children_field: false)
  end

  before do
    login_as(user, scope: :user)
    visit root_path
    click_link "Vos informations"
  end

  it "shows the user information" do
    expect(page).to have_content "Mes informations"
    expect(page).not_to have_content "Nombre d'enfants"
    select "MSA", from: "Caisse d'affiliation"
    fill_in "Numéro d'allocataire", with: 123
    click_on("Modifier")
    expect(page).to have_content "Vos informations ont été mises à jour."
    expect(user.reload.affiliation_number).to eq "123"
  end
end
