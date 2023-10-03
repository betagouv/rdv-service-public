# frozen_string_literal: true

RSpec.describe TransferEmailReplyJob do
  subject(:perform_job) { described_class.perform_now(sendinblue_payload) }

  before do
    # Set a fixed date so we can assert on dates within email body
    travel_to(Time.zone.parse("2022-05-17 16:00:00"))
  end

  let!(:user) { create(:user, email: "bene_ficiaire@lapin.fr", first_name: "Bénédicte", last_name: "Ficiaire") }
  let!(:agent) { create(:agent, email: "je_suis_un_agent@departement.fr") }
  let(:rdv_uuid) { "8fae4d5f-4d63-4f60-b343-854d939881a3" }
  let!(:rdv) { create(:rdv, users: [user], agents: [agent], uuid: rdv_uuid) }

  let(:sendinblue_valid_payload) do
    # The usual payload has more info, but I removed non-essential fields for readability.
    # See: https://developers.sendinblue.com/docs/inbound-parsing-api-1#sample-payload
    {
      Cc: [],
      ReplyTo: nil,
      Subject: "coucou",
      Attachments: [],
      Headers: {
        "Message-ID": "<d6c8663e3763aa750345a76c17f435a2bd14eded.camel@lapin.fr>",
        Subject: "coucou",
        From: "Bénédicte Ficiaire <bene_ficiaire@lapin.fr>",
        To: "rdv+8fae4d5f-4d63-4f60-b343-854d939881a3@reply.rdv-solidarites.fr",
        Date: "Thu, 12 May 2022 12:22:15 +0200",
      },
      ExtractedMarkdownMessage: "Je souhaite annuler mon RDV",
      ExtractedMarkdownSignature: nil,
      RawHtmlBody: %(<html dir="ltr"><head></head><body style="text-align:left; direction:ltr;"><div>Je souhaite annuler mon RDV</div>\n</body></html>\n),
      RawTextBody: "Je souhaite annuler mon RDV\n",
    }
  end
  let(:sendinblue_payload) { sendinblue_valid_payload } # use valid payload by default

  context "when all goes well" do
    it "sends a notification email to the agent, containing the user reply" do
      expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
      transferred_email = ActionMailer::Base.deliveries.last
      expect(transferred_email.to).to eq(["je_suis_un_agent@departement.fr"])
      expect(transferred_email[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
      expect(transferred_email.html_part.body.to_s).to include("Dans le cadre du RDV du 20 mai, l'usager⋅e Bénédicte FICIAIRE a envoyé")
      expect(transferred_email.html_part.body.to_s).to include("Je souhaite annuler mon RDV") # reply content
      expect(transferred_email.html_part.body.to_s).to include(%(href="http://www.rdv-solidarites-test.localhost/admin/organisations/#{rdv.organisation_id}/rdvs/#{rdv.id}))
    end
  end

  context "when reply token does not match any in DB" do
    let(:rdv_uuid) { "6df62597-632e-4be1-a273-708ab58e4765" }

    stub_sentry_events

    it "sends a notification email to the default mailbox, containing the user reply" do
      expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
      transferred_email = ActionMailer::Base.deliveries.last
      expect(transferred_email.to).to eq(["support@rdv-solidarites.fr"])
      expect(transferred_email.from).to eq(["support@rdv-solidarites.fr"])
      expect(transferred_email.html_part.body.to_s).to include(%(L'usager⋅e "Bénédicte Ficiaire" &lt;bene_ficiaire@lapin.fr&gt; a répondu))
      expect(transferred_email.html_part.body.to_s).to include("Je souhaite annuler mon RDV") # reply content
    end
  end

  context "when an e-mail address does not match our pattern" do
    let(:sendinblue_payload) do
      sendinblue_valid_payload.tap { |hash| hash[:Headers][:To] = "nimportequoi@reply.rdv-solidarites.fr" }
    end

    it "is forwarded to default mailbox" do
      expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
      transferred_email = ActionMailer::Base.deliveries.last
      expect(transferred_email.to).to eq(["support@rdv-solidarites.fr"])
      expect(transferred_email.html_part.body.to_s).to include(%(L'usager⋅e "Bénédicte Ficiaire" &lt;bene_ficiaire@lapin.fr&gt; a répondu))
    end
  end

  context "when several agents are linked to the RDV" do
    let!(:other_agent) { create(:agent, email: "autre@departement.fr").tap { |a| rdv.agents << a } }

    it "sends one email with all agents in the TO: field" do
      perform_job
      expect(ActionMailer::Base.deliveries.last.to).to match_array(["je_suis_un_agent@departement.fr", "autre@departement.fr"])
    end
  end

  context "when attachments are present" do
    let(:sendinblue_payload) do
      sendinblue_valid_payload.tap do |hash|
        hash[:Attachments] = [{ Name: "mon_scan.pdf", ContentType: "application/pdf" }]
      end
    end

    it "mentions the attachments in the notification e-mail" do
      expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
      transferred_email = ActionMailer::Base.deliveries.last
      expect(transferred_email.html_part.body.to_s).to include(%(Le mail de l'usager⋅e avait en pièce jointe "mon_scan.pdf".))
    end
  end
end
