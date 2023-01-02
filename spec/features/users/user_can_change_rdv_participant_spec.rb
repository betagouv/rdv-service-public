# frozen_string_literal: true

describe "User can change rdv participant" do
  let(:rdv) { create(:rdv) }
  let(:user) { rdv.users.first }
  let!(:child) { create(:user, first_name: "Petit", last_name: "BEBE", responsible_id: user.id) }

  before do
    login_as(user, scope: :user)
    visit users_rdvs_path
  end

  %w[individual collectif].each do |rdv_type|
    context "with an #{rdv_type} rdv" do
      let(:rdv) { create(:rdv, :collectif) } if rdv_type == "collectif"

      it "works" do
        expect(page).to have_content(rdv.motif.name)
        click_link("modifier")
        find("label", text: "Petit BEBE").click
        click_button("Enregistrer")
        expect(page).to have_content("Participation confirmée")
        expect(page).to have_content("Petit BEBE")
      end
    end
  end
end
