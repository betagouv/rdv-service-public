RSpec.describe "Admin can configure the organisation" do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit new_admin_organisation_user_path(organisation)
  end

  it "CRUD on lieux", :js do
    expect_page_title("Nouvel usager")
    choose("Proche")
    fill_in("Prénom", with: "enfant-prenom", match: :first)
    fill_in("Nom", with: "enfant-nom", match: :first)
    click_on("Nouvel Usager")
    fill_in("user_responsible_attributes_first_name", with: "parent-prenom")
    fill_in("user_responsible_attributes_last_name", with: "parent-nom")

    click_button("Créer usager")
    expect_page_title("enfant-prenom ENFANT-NOM")
    expect(User.all.map(&:last_name)).to eq(%w[parent-nom enfant-nom])
  end
end
