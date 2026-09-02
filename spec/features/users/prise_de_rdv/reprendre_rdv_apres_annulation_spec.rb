REPRENDRE_RDV_URL_REGEX = %r{https?://\S+/prdv\?tkn=[A-Z0-9]+}

RSpec.describe "Liens reprendre RDV après annulation (email et SMS)" do
  context "sur RDVS, RDV individuel avec une seule participation, notifier RdvCancelled" do
    let(:territory) { create(:territory) }
    let(:organisation) { create(:organisation, territory:, verticale: :rdv_solidarites) }
    let(:autre_organisation) { create(:organisation, territory:, verticale: :rdv_solidarites) }
    let(:motif) { create(:motif, name: "Accompagnement", organisation:, bookable_by: :everyone) }
    let(:autre_motif) { create(:motif, name: "Accompagnement", organisation: autre_organisation, bookable_by: :everyone) }
    let(:lieu) { create(:lieu, name: "MDS Issy", organisation:) }
    let(:autre_lieu) { create(:lieu, name: "MDS Là bas", organisation: autre_organisation) }
    let(:user) { create(:user, last_name: "Dupont") }
    let(:agent) { create(:agent) }
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu:, organisation:) }
    let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [autre_motif], lieu: autre_lieu, organisation: autre_organisation) }
    let(:rdv) { create(:rdv, :excused, organisation:, motif:, lieu:, users: [user]) }

    it "amène à la recherche scopée pour l’organisation du RDV annulé, via le lien de l’email ou du SMS" do
      stub_netsize_ok
      Notifiers::RdvCancelled.perform_with(rdv, agent)
      perform_enqueued_jobs
      mail_body = first_email_sent_to(user.email).html_part.body.to_s
      mail_link_url = Nokogiri::HTML(mail_body).to_s.match(REPRENDRE_RDV_URL_REGEX)&.to_s
      sms_link_url = Receipt.last.content.match(REPRENDRE_RDV_URL_REGEX)&.to_s
      expect(mail_link_url).to eq sms_link_url
      visit mail_link_url
      fill_in "3 premières lettres de votre nom", with: "DUP"
      click_on "Valider"
      expect(page).to have_content("MDS Issy")
      expect(page).not_to have_content("MDS Là bas")
    end
  end

  context "sur RDVSP, RDV individuel avec une seule participation, notifier RdvCancelled" do
    let(:territory) { create(:territory) }
    let(:organisation) { create(:organisation, territory:, verticale: :rdv_mairie) }
    let(:autre_organisation) { create(:organisation, territory:, verticale: :rdv_mairie) }
    let(:motif) { create(:motif, name: "Accompagnement", organisation:, bookable_by: :everyone) }
    let(:autre_motif) { create(:motif, name: "Accompagnement", organisation: autre_organisation, bookable_by: :everyone) }
    let(:lieu) { create(:lieu, name: "MDS Issy", organisation:) }
    let(:autre_lieu) { create(:lieu, name: "MDS Là bas", organisation: autre_organisation) }
    let(:user) { create(:user, last_name: "Dupont") }
    let(:agent) { create(:agent) }
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu:, organisation:) }
    let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [autre_motif], lieu: autre_lieu, organisation: autre_organisation) }
    let(:rdv) { create(:rdv, :excused, organisation:, motif:, lieu:, users: [user]) }

    it "amène à la recherche scopée pour l’organisation du RDV annulé, via le lien de l’email ou du SMS" do
      stub_netsize_ok
      Notifiers::RdvCancelled.perform_with(rdv, agent)
      perform_enqueued_jobs
      mail_body = first_email_sent_to(user.email).html_part.body.to_s
      mail_link_url = Nokogiri::HTML(mail_body).to_s.match(REPRENDRE_RDV_URL_REGEX)&.to_s
      sms_link_url = Receipt.last.content.match(REPRENDRE_RDV_URL_REGEX)&.to_s
      expect(mail_link_url).to eq sms_link_url
      visit mail_link_url
      fill_in "3 premières lettres de votre nom", with: "DUP"
      click_on "Valider"
      expect(page).to have_content("MDS Issy")
      expect(page).not_to have_content("MDS Là bas")
    end
  end

  context "RDV avec plusieurs participations, notifier ParticipationCancelled" do
    let(:territory) { create(:territory) }
    let(:organisation) { create(:organisation, territory:) }
    let(:autre_organisation) { create(:organisation, territory:) }
    let(:motif) { create(:motif, name: "Accompagnement", organisation:, bookable_by: :everyone) }
    let(:autre_motif) { create(:motif, name: "Accompagnement", organisation: autre_organisation, bookable_by: :everyone) }
    let(:lieu) { create(:lieu, name: "MDS Issy", organisation:) }
    let(:autre_lieu) { create(:lieu, name: "MDS Là bas", organisation: autre_organisation) }
    let(:user) { create(:user, last_name: "Dupont") }
    let(:agent) { create(:agent) }
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu:, organisation:) }
    let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [autre_motif], lieu: autre_lieu, organisation: autre_organisation) }
    let(:autre_user) { create(:user) }
    let(:rdv) { create(:rdv, organisation:, motif:, lieu:, users: [user, autre_user]) }
    let(:participation) { rdv.participations.find_by(user:) }

    it "amène à la recherche scopée pour l’organisation du RDV annulé, via le lien de l’email ou du SMS" do
      stub_netsize_ok
      Notifiers::ParticipationCancelled.perform_with(participation:, author: agent)
      perform_enqueued_jobs
      mail_body = first_email_sent_to(user.email).body.to_s
      mail_link_url = Nokogiri::HTML(mail_body).to_s.match(REPRENDRE_RDV_URL_REGEX)&.to_s
      sms_link_url = Receipt.last.content.match(REPRENDRE_RDV_URL_REGEX)&.to_s
      expect(mail_link_url).to eq sms_link_url
      visit mail_link_url
      fill_in "3 premières lettres de votre nom", with: "DUP"
      click_on "Valider"
      expect(page).to have_content("MDS Issy")
      expect(page).not_to have_content("MDS Là bas")
    end
  end

  context "RDV non réservable publiquement par les usagers" do
    let(:territory) { create(:territory) }
    let(:organisation) { create(:organisation, territory:) }
    let(:motif) { create(:motif, name: "Accompagnement", organisation:, bookable_by: "agents") }
    let(:lieu) { create(:lieu, name: "MDS Issy", organisation:) }
    let(:user) { create(:user) }
    let(:agent) { create(:agent, organisations: [organisation]) }
    let(:rdv) { create(:rdv, organisation:, motif:, lieu:, users: [user], agents: [agent]) }
    let(:participation) { rdv.participations.find_by(user:) }

    it "n'affiche pas de lien pour reprendre RDV ni dans le mail ni dans le SMS" do
      stub_netsize_ok
      Notifiers::ParticipationCancelled.perform_with(participation:, author: agent)
      perform_enqueued_jobs
      mail_body = first_email_sent_to(user.email).body.to_s
      mail_link_url = Nokogiri::HTML(mail_body).to_s.match(REPRENDRE_RDV_URL_REGEX)&.to_s
      sms_link_url = Receipt.last.content.match(REPRENDRE_RDV_URL_REGEX)&.to_s
      expect(mail_link_url).to be_blank
      expect(sms_link_url).to be_blank
    end
  end
end
