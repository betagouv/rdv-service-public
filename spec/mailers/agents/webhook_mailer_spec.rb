RSpec.describe Agents::WebhookMailer, type: :mailer do
  describe "#new_webhook_url" do
    it "works" do
      webhook = create(:webhook_endpoint)
      notified_agent = create(:agent)
      mail = described_class.new_webhook_url(webhook_endpoint_id: webhook.id, notified_agent_id: notified_agent.id)

      expect(mail[:from].to_s).to eq("RDV Service Public <secretariat-auto@rdv-service-public.fr>")
      expect(mail.to).to eq([notified_agent.email])
      expect(mail.subject).to eq("Une nouvelle URL de webhook vient d'être ajoutée")

      expect(mail.body.encoded).to include("Une nouvelle URL de webhook vient d'être introduite")
      expect(mail.body.encoded).to include(%(href="http://www.rdv-service-public-test.localhost/admin/territories/#{webhook.territory.id}/webhook_endpoints"))
      expect(mail.body.encoded).to include(webhook.target_url)
    end

    it "mentions the author when present" do
      author = create(:agent, first_name: "Amine", last_name: "Despace")
      notified_agent = create(:agent)
      PaperTrail.request.whodunnit = author.name_for_paper_trail
      mail = described_class.new_webhook_url(webhook_endpoint_id: create(:webhook_endpoint).id, notified_agent_id: notified_agent.id)

      expect(mail.body.encoded).to include("par Amine DESPACE")
    end

    it "speaks to you at the second person" do
      author = create(:agent, first_name: "Amine", last_name: "Despace")
      PaperTrail.request.whodunnit = author.name_for_paper_trail
      mail = described_class.new_webhook_url(webhook_endpoint_id: create(:webhook_endpoint).id, notified_agent_id: author.id)

      expect(mail.subject).to eq("Vous venez d'ajouter une nouvelle URL de webhook")
      expect(mail.body.encoded).to include("Vous venez d'introduire une nouvelle URL de webhook :")
    end

    it "specifies when the operation was done via API" do
      author = create(:agent, first_name: "Amine", last_name: "Despace")
      notified_agent = create(:agent)
      PaperTrail.request.whodunnit = "#{author.name_for_paper_trail} (via API)"

      mail = described_class.new_webhook_url(webhook_endpoint_id: create(:webhook_endpoint).id, notified_agent_id: notified_agent.id)

      expect(mail.subject).to eq("Un webhook vient d'être ajouté par API")
      puts mail.body.encoded
      expect(mail.body.encoded).to include("Une nouvelle URL de webhook vient d'être introduite par Amine DESPACE (via API) :")
    end
  end
end
