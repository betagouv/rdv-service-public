RSpec.describe "User views his rdv" do
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
      expect(page).to have_content("Le #{I18n.l(rdv.starts_at, format: :human)} (durée&nbsp;: #{rdv.duration_in_min} minutes)")
      click_link "Voir vos RDV passés"
      expect_page_with_no_record_text("Vous n'avez pas de RDV passés")
    end
  end

  it "even past rdvs" do
    now = Time.zone.parse("2021-04-25 18:00")
    travel_to(now - 1.week)
    rdv = create(:rdv, starts_at: now - 3.days, users: [user], organisation: organisation)

    travel_to(now)
    click_link "Vos rendez-vous"
    expect_page_with_no_record_text("Vous n'avez pas de RDV à venir")
    click_link "Voir vos RDV passés"
    expect(page).to have_content("Le #{I18n.l(rdv.starts_at, format: :human)} (durée&nbsp;: #{rdv.duration_in_min} minutes)")
  end
end
