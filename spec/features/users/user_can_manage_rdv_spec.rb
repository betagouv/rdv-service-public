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

      it "default", js: true do
        expect(page).to have_content(rdv.motif_name)
        click_on("Annuler le RDV")
        expect(page).to have_content("Confirmation")
        click_link("Oui, annuler le rendez-vous")
        expect(page).to have_selector(".fr-badge", text: "ANNULÉ")
      end
    end

    context "when not cancellable" do
      let(:starts_at) { 4.hours.from_now }

      it "default", js: true do
        expect(page).to have_content(rdv.motif_name)
        expect(page).not_to have_selector("li", text: "Annuler le RDV")
        expect(page).to have_content("Ce rendez-vous n'est pas annulable en ligne. Prenez contact avec le secrétariat.")
      end
    end

    context "when available for file attente" do
      let(:starts_at) { 15.days.from_now }

      it "default", js: true do
        expect(page).to have_content("Je souhaite être prévenu(e) si un créneau se libère.")
        find(:label, text: "Je souhaite être prévenu(e) si un créneau se libère.").click
        # cannot use check/uncheck here, playwright throws Element is not attached to the DOM
        expect(page).to have_content("Vous êtes à présent sur la liste d'attente")
        find(:label, text: "Je souhaite être prévenu(e) si un créneau se libère.").click
        expect(page).to have_content("Vous n'êtes plus sur la liste d'attente")
      end
    end

    context "when not available for file attente" do
      let(:starts_at) { 7.days.from_now }

      it "default", js: true do
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
    let!(:rdv) { create(:rdv, users: [user], agents: [agent1], starts_at: 10.days.from_now, created_by: user, motif: motif, lieu: lieu, organisation:) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, organisation: organisation, agent: agent2) }

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
          expect(page).to have_content("Vous allez modifier votre RDV #{motif.name} qui a lieu le #{I18n.l(rdv.starts_at, format: :human)}")
          click_link("Confirmer le nouveau créneau")
          expect(rdv.reload.starts_at).not_to eq(original_date)

          # Check Notifications
          perform_enqueued_jobs
          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.any? { |mail| mail.to == [agent1.email] && mail.subject == "RDV annulé #{relative_date(original_date)}" }).to be true
          expect(deliveries.any? do |mail|
                   mail.to == [agent2.email] && mail.subject == "Nouveau RDV ajouté sur votre agenda RDV Service Public pour #{relative_date(rdv.reload.starts_at)}"
                 end).to be true
          expect(deliveries.any? { |mail| mail.to == [user.email] && mail.subject == "RDV du #{I18n.l(original_date, format: :human)} modifié" }).to be true
        end
      end
    end
  end

  describe "l’usager suit un lien d’annulation envoyé par SMS ou mail", js: true do
    let(:user) { create(:user, last_name: "Factice") }
    let!(:organisation) { create(:organisation, name: "93 Social") }
    let(:lieu) { create(:lieu, name: "CCAS de Montreuil", organisation:) }
    let!(:rdv) { create(:rdv, organisation:, starts_at: 4.days.from_now, users: [user], lieu:) }

    it "ne fait pas d’erreur si on rafraichit la page de vérification du nom" do # refresh does not seem to work without js: true 🤷
      visit users_rdv_path(rdv.id, invitation_token: rdv.participations.first.restricted_auth_token)
      fill_in(:letters, with: "FAX") # voluntary error here
      click_on "Valider"
      expect(page).to have_content(/Les 3 lettres ne correspondent pas/)
      refresh
      expect(page).to have_content(/veuillez entrer les 3 premières lettres/)
      fill_in(:letters, with: "FAC")
      click_on "Valider"
      expect(page).to have_content "Votre RDV"
    end
  end
end
