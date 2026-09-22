RSpec.describe "Agents can send an invitation to a rdv" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let(:rdv_invitation) { create(:rdv_invitation, motif:, lieu:, user:, inviting_agent: agent) }

  let(:motif) { create(:motif, organisation:) }
  let(:lieu) { create(:lieu, organisation:) }

  before { login_as agent, scope: :agent }

  context "when the user doesn't have an email address" do
    let(:user) { create(:user, email: nil, organisations: [organisation]) }

    it "shows an error message" do
      visit new_admin_organisation_rdv_invitation_path(organisation, motif_id: motif.id, lieu_id: lieu.id, user_id: user.id)
      click_on "Envoyer l'invitation"
      expect(page).to have_content "ne peut donc pas recevoir d'invitation"
      expect(RdvInvitation.count).to eq 0
    end
  end

  describe "creating a new user" do
    it "works" do
      visit new_admin_organisation_rdv_invitation_path(organisation, motif_id: motif.id, lieu_id: lieu.id)
      click_on "Ajouter un usager"

      fill_in "Prénom", with: "Francis"
      fill_in "Nom d’usage", with: "Factice"

      fill_in "Email", with: "francis@factice.org"
      click_on "Enregistrer"

      expect(page).to have_content "Vous allez inviter Francis FACTICE"

      expect(User.last).to have_attributes(
        first_name: "Francis",
        last_name: "Factice",
        email: "francis@factice.org",
        organisations: [organisation]
      )
    end
  end

  describe "selecting the user" do
    let(:user) { create(:user, organisations: [organisation], first_name: "Francis", last_name: "Factice") }

    it "works", js: true do
      visit new_admin_organisation_rdv_invitation_path(organisation, motif_id: motif.id, lieu_id: lieu.id)

      find(".select2-selection__placeholder").click

      within(".select2-search--dropdown") do
        fill_in(class: "select2-search__field", with: user.first_name)
      end
      expect(page).to have_content "FACTICE Francis"

      find("li", text: "FACTICE Francis", match: :first).click

      expect(page).to have_content "Vous allez inviter Francis FACTICE"
    end
  end
end
