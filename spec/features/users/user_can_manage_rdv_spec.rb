RSpec.describe "User can manage their rdvs" do
  context "rdv are created by an agent" do
    let(:rdv) { create(:rdv, starts_at: starts_at) }
    let(:user) { rdv.users.first }

    before do
      login_as(user, scope: :user)
      visit users_rdvs_path
    end

    context "when cancellable" do
      let(:starts_at) { 5.hours.from_now }

      it "default", :js do
        expect(page).to have_content(rdv.motif_name)
        click_link("Annuler le RDV")
        expect(page).to have_content("Confirmation")
        click_link("Oui, annuler le rendez-vous")
        expect(page).to have_selector(".badge", text: "Annulé")
      end
    end

    context "when not cancellable" do
      let(:starts_at) { 4.hours.from_now }

      it "default", :js do
        expect(page).to have_content(rdv.motif_name)
        expect(page).not_to have_selector("li", text: "Annuler le RDV")
        expect(page).to have_content("Ce rendez-vous n'est pas annulable en ligne. Prenez contact avec le secrétariat.")
      end
    end

    context "when available for file attente" do
      let(:starts_at) { 15.days.from_now }

      it "default", :js do
        expect(page).to have_content("Je souhaite être prévenu si un créneau se libère.")
        check "Je souhaite être prévenu si un créneau se libère."
        expect(page).to have_content("Vous êtes à présent sur la liste d'attente")
        uncheck "Je souhaite être prévenu si un créneau se libère."
        expect(page).to have_content("Vous n'êtes plus sur la liste d'attente")
      end
    end

    context "when not available for file attente" do
      let(:starts_at) { 7.days.from_now }

      it "default", :js do
        expect(page).not_to have_content("Je souhaite être prévenu si un créneau se libère.")
      end
    end
  end

  context "rdv are created by the user" do
    let!(:organisation) { create(:organisation) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:agent1) { create(:agent, organisations: [organisation]) }
    let!(:agent2) { create(:agent, organisations: [organisation]) }
    let!(:user) { create(:user, organisations: [organisation]) }
    let!(:motif) { create(:motif, organisation: organisation) }
    let!(:rdv) { create(:rdv, users: [user], agents: [agent1], starts_at: 10.days.from_now, created_by: user, motif: motif, lieu: lieu) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, organisation: organisation, agent: agent2) }

    before do
      stub_netsize_ok
      login_as(user, scope: :user)
      visit users_rdvs_path
    end

    context "when rdv is editable" do
      context "when user change the date" do
        it "notify agents if rdv agent change" do
          original_date = rdv.starts_at
          # User change the date
          click_link("Déplacer le RDV")
          first(:link, "11:00").click
          expect(page).to have_content("Vous allez modifier votre RDV #{motif.name} - #{motif.service.name} qui a lieu le #{I18n.l(rdv.starts_at, format: :human)}")
          click_link("Confirmer le nouveau créneau")
          expect(rdv.reload.starts_at).not_to eq(original_date)

          # Check Notifications
          perform_enqueued_jobs
          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.any? { |mail| mail.to == [agent1.email] && mail.subject == "RDV annulé #{relative_date(original_date)}" }).to be true
          expect(deliveries.any? do |mail|
                   mail.to == [agent2.email] && mail.subject == "Nouveau RDV ajouté sur votre agenda RDV Solidarités pour #{relative_date(rdv.reload.starts_at)}"
                 end).to be true
          expect(deliveries.any? { |mail| mail.to == [user.email] && mail.subject == "RDV du #{I18n.l(original_date, format: :human)} modifié" }).to be true
        end
      end
    end
  end
end
