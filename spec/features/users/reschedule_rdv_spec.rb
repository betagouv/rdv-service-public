RSpec.describe "User can reschedule their rdvs" do
  let!(:organisation) { create(:organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:agent1) { create(:agent, organisations: [organisation]) }
  let!(:agent2) { create(:agent, organisations: [organisation]) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:rdv) { create(:rdv, users: [user], agents: [agent1], starts_at: 10.days.from_now, created_by: user, motif: motif, lieu: lieu, organisation:) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, organisation: organisation, agent: agent2) }

  before do
    stub_netsize_ok
    login_as(user, scope: :user)
    visit users_rdvs_path
  end

  it "notify agents if rdv agent change" do
    original_date = rdv.starts_at
    # User change the date
    click_link("Déplacer le RDV")
    first(:link, "11:00").click
    expect(page).to have_content("Vous allez modifier votre RDV #{motif.name} qui a lieu le #{I18n.l(rdv.starts_at, format: :human)}")
    click_link("Confirmer le nouveau créneau")
    expect(rdv.reload.starts_at).not_to eq(original_date)

    # Check Notifications
    perform_enqueued_jobs
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.any? { |mail| mail.to == [agent1.email] && mail.subject == "RDV #{relative_date_with_preposition(original_date)} annulé" }).to be true
    expect(deliveries.any? do |mail|
             mail.to == [agent2.email] && mail.subject == "Nouveau RDV ajouté pour #{relative_date(rdv.reload.starts_at)} sur votre agenda RDV Service Public"
           end).to be true
    expect(deliveries.any? { |mail| mail.to == [user.email] && mail.subject == "RDV du #{I18n.l(original_date, format: :human)} modifié" }).to be true
  end

  context "for a follow-up rdv" do
    let!(:motif) { create(:motif, organisation: organisation, follow_up: true) }
    let(:referent) { create(:agent, organisations: [organisation]) }

    before do
      create(:referent_assignation, user:, agent: referent)
      create(:plage_ouverture, :weekdays, motifs: [motif], lieu:, organisation:, agent: referent, start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15))
    end

    it "only displays the creneaux of the referent" do
      click_link("Déplacer le RDV")
      expect(page).not_to have_content "8:00"
      expect(page).to have_content "14:00"
    end

    # TODO: faire une spec quand l'usager du rdv est un proche de l'usager connecté
  end

  context "when the rdv doesn't have the same duration as the motif (usually for an ANTS motif and multiple users)" do
    let!(:motif) { create(:motif, organisation: organisation, default_duration_in_min: 30) }
    let(:starts_at) { 10.days.from_now }
    let!(:rdv) { create(:rdv, users: [user], agents: [agent1], starts_at:, ends_at: starts_at + 60.minutes, created_by: user, motif:, lieu:, organisation:) }

    it "affiche des créneaux de 60 min" do
      click_link("Déplacer le RDV")
      expect(page).to have_content "8:00"
      expect(page).not_to have_content "8:30"
      expect(page).to have_content "9:00"
    end
  end
end
