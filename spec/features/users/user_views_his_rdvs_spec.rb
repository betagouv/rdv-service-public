describe "User views his rdv" do
  let!(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }

  before do
    login_as(user, scope: :user)
    visit root_path
    click_link "Vos rendez-vous"
  end

  context "with no rdv" do
    it { expect_page_with_no_record_text("Vous n'avez pas de RDV à venir") }
  end

  context "with future rdv" do
    let!(:rdv) { create(:rdv, :future, users: [user], organisation: organisation) }
    before { click_link "Vos rendez-vous" }
    it do
      expect(page).to have_content(rdv_title_spec(rdv))
      click_link "Voir vos RDV passés"
      expect_page_with_no_record_text("Vous n'avez pas de RDV passés")
    end
  end

  context "with past rdv" do
    let!(:rdv) { create(:rdv, :past, users: [user], organisation: organisation) }
    before { click_link "Vos rendez-vous" }
    it do
      expect_page_with_no_record_text("Vous n'avez pas de RDV à venir")
      click_link "Voir vos RDV passés"
      expect(page).to have_content(rdv_title_spec(rdv))
    end
  end
end
