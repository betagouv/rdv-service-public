RSpec.describe "Liens reprendre RDV depuis les emails d'annulation" do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory:) }
  let(:autre_organisation) { create(:organisation, territory:) }
  let(:motif) { create(:motif, name: "Accompagnement", organisation:) }
  let(:autre_motif) { create(:motif, name: "Accompagnement", organisation: autre_organisation) }
  let(:lieu) { create(:lieu, name: "MDS Issy", organisation:) }
  let(:autre_lieu) { create(:lieu, name: "MDS Là bas", organisation: autre_organisation) }
  let(:user) { create(:user) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu:, organisation:) }
  let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [autre_motif], lieu: autre_lieu, organisation: autre_organisation) }

  context "Rdv individuel, RdvCancelled" do
    let(:rdv) { create(:rdv, :excused, organisation:, motif:, lieu:, users: [user]) }

    it "amène à la recherche scopée pour l’organisation du RDV annulé" do
      Notifiers::RdvCancelled.perform_with(rdv, user)
      perform_enqueued_jobs
      mail_body = first_email_sent_to(user.email).html_part.body.to_s
      link_url = Nokogiri::HTML(mail_body).at_css('a[href*="prendre_rdv"]')["href"]
      visit link_url
      expect(page).to have_content("MDS Issy")
      expect(page).not_to have_content("MDS Là bas")
    end
  end

  describe "Plusieurs usagers dans le RDV, participation d'un usager uniquement annulée" do
    let(:autre_user) { create(:user) }
    let(:rdv) { create(:rdv, organisation:, motif:, lieu:, users: [user, autre_user]) }
    let(:participation) { rdv.participations.find_by(user:) }

    it "amène à la recherche scopée pour l’organisation du RDV annulé" do
      Notifiers::ParticipationCancelled.perform_with(participation:, author: user)
      perform_enqueued_jobs
      mail_body = first_email_sent_to(user.email).body.to_s
      link_url = Nokogiri::HTML(mail_body).at_css('a[href*="prendre_rdv"]')["href"]
      visit link_url
      expect(page).to have_content("MDS Issy")
      expect(page).not_to have_content("MDS Là bas")
    end
  end
end
