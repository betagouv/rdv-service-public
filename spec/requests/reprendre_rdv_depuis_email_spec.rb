RSpec.describe "Lien Reprendre RDV depuis les emails d'annulation", type: :request do
  describe "rdv_cancelled sur RDVS" do
    it "dirige vers la sélection de lieu après suivi des redirections" do
      organisation = create(:organisation, verticale: :rdv_solidarites)
      motif = create(:motif, organisation:)
      lieu = create(:lieu, organisation:)
      create(:plage_ouverture, motifs: [motif], lieu:, organisation:)
      user = create(:user)
      token = user.set_rdv_invitation_token!
      rdv = create(:rdv, organisation:, motif:, lieu:, users: [user])

      mail = Users::RdvMailer.with(rdv:, user:, token:).rdv_cancelled
      link_url = Nokogiri::HTML(mail.html_part.body.to_s).at_css('a[href*="prendre_rdv"]')["href"]
      get link_url
      follow_redirect! while response.redirect?
      expect(response).to be_successful
      expect(response.body).to include(lieu.name)
    end
  end

  describe "rdv_cancelled sur RDVSP" do
    it "dirige vers la sélection de lieu après suivi des redirections, sans être bloqué par la guard-clause géographique" do
      organisation = create(:organisation, verticale: :rdv_mairie)
      motif = create(:motif, organisation:)
      lieu = create(:lieu, organisation:)
      create(:plage_ouverture, motifs: [motif], lieu:, organisation:)
      user = create(:user)
      token = user.set_rdv_invitation_token!
      rdv = create(:rdv, organisation:, motif:, lieu:, users: [user])

      mail = Users::RdvMailer.with(rdv:, user:, token:).rdv_cancelled
      link_url = Nokogiri::HTML(mail.html_part.body.to_s).at_css('a[href*="prendre_rdv"]')["href"]
      get link_url
      follow_redirect! while response.redirect?
      expect(response).to be_successful
      expect(response.body).to include(lieu.name)
    end
  end

  describe "participation_cancelled sur RDVS" do
    it "dirige vers la sélection de lieu après suivi des redirections" do
      organisation = create(:organisation, verticale: :rdv_solidarites)
      motif = create(:motif, :collectif, organisation:)
      lieu = create(:lieu, organisation:)
      create(:plage_ouverture, motifs: [motif], lieu:, organisation:)
      user = create(:user)
      token = user.set_rdv_invitation_token!
      rdv = create(:rdv, :collectif, organisation:, motif:, lieu:)
      participation = create(:participation, rdv:, user:)

      mail = Users::RdvMailer.with(rdv:, user:, token:, participation:).participation_cancelled
      link_url = Nokogiri::HTML(mail.body.to_s).at_css('a[href*="prendre_rdv"]')["href"]
      get link_url
      follow_redirect! while response.redirect?
      expect(response).to be_successful
      expect(response.body).to include(lieu.name)
    end
  end

  describe "participation_cancelled sur RDVSP" do
    it "dirige vers la sélection de lieu après suivi des redirections, sans être bloqué par la guard-clause géographique" do
      organisation = create(:organisation, verticale: :rdv_mairie)
      motif = create(:motif, :collectif, organisation:)
      lieu = create(:lieu, organisation:)
      create(:plage_ouverture, motifs: [motif], lieu:, organisation:)
      user = create(:user)
      token = user.set_rdv_invitation_token!
      rdv = create(:rdv, :collectif, organisation:, motif:, lieu:)
      participation = create(:participation, rdv:, user:)

      mail = Users::RdvMailer.with(rdv:, user:, token:, participation:).participation_cancelled
      link_url = Nokogiri::HTML(mail.body.to_s).at_css('a[href*="prendre_rdv"]')["href"]
      get link_url
      follow_redirect! while response.redirect?
      expect(response).to be_successful
      expect(response.body).to include(lieu.name)
    end
  end
end
