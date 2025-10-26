RSpec.describe Agents::SecurityMailer, type: :mailer do
  describe "#new_webhook_url" do
    it "works" do
      webhook = create(:webhook_endpoint)
      notified_agent = create(:agent)
      mail = described_class.new_webhook_url(webhook_endpoint_id: webhook.id, notified_agent_id: notified_agent.id)

      expect(mail[:from].to_s).to eq("RDV Service Public <secretariat-auto@rdv-service-public.fr>")
      expect(mail.to).to eq([notified_agent.email])

      expect(mail.body.encoded).to include("Une nouvelle URL de webhook vient d'être introduite")
      expect(mail.body.encoded).to include(%(href="http://www.rdv-mairie-test.localhost/admin/territories/#{webhook.territory.id}/webhook_endpoints/#{webhook.id}/edit"))
      expect(mail.body.encoded).to include(webhook.target_url)
    end

    it "mentions the author when present" do
      author = create(:agent, first_name: "Amine", last_name: "Despace")
      PaperTrail.request.whodunnit = author.name_for_paper_trail
      mail = described_class.new_webhook_url(webhook_endpoint_id: create(:webhook_endpoint).id, notified_agent_id: create(:agent).id)

      expect(mail.body.encoded).to include("par Amine DESPACE")
    end
  end
end
