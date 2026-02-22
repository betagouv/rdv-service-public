RSpec.describe "User views his rdv" do
  let!(:organisation) { organisations(:default_org) }
  let(:user) { create(:user, organisations: [organisation]) }

  before do
    login_as(user, scope: :user)
    visit root_path
    click_link "Vos rendez-vous"
  end

  context "with no rdv" do
    it "tells the user she has no rdv" do
      expect(page).to have_content("Vous n'avez pas de RDV à venir")
      expect(page).not_to have_content("Voir vos RDV passés")
    end
  end

  context "with future rdv" do
    let!(:rdv) { create(:rdv, :future, users: [user], organisation: organisation) }

    it do
      click_link "Vos rendez-vous"
      expect(page).to have_content("Le #{I18n.l(rdv.starts_at, format: :human)} (durée : #{rdv.duration_in_min} minutes)")
      expect(page).not_to have_content("Voir vos RDV passés")
    end
  end

  it "even past rdvs" do
    now = Time.zone.parse("2021-04-25 18:00")
    travel_to(now - 1.week)
    rdv = create(:rdv, starts_at: now - 3.days, users: [user], organisation: organisation)

    travel_to(now)
    click_link "Vos rendez-vous"
    expect(page).to have_content("Vous n'avez pas de RDV à venir")
    click_link "Voir vos RDV passés"
    expect(page).to have_content("Le #{I18n.l(rdv.starts_at, format: :human)} (durée : #{rdv.duration_in_min} minutes)")
  end
end
