RSpec.describe "User can reschedule their rdvs" do
  context "rdv are created by the user" do
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
  end
end
