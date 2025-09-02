RSpec.describe TransferEmailReplyJob do
  describe "#uuid_from_email_address" do
    %w[
      rdv+b1a2-3c4f@reply.rdv-solidarites.fr
      rdv+b1a2-3c4f@reply.rdv-aide-numerique.fr
      rdv+b1a2-3c4f@reply.rdv-service-public.fr
      rdv+b1a2-3c4f@reply.staging.rdv-service-public.fr
      rdv+b1a2-3c4f@reply.demo.rdv-solidarites.fr
      rdv+b1a2-3c4f@reply.demo.rdv-aide-numerique.fr
      rdv+b1a2-3c4f@reply.demo.rdv-service-public.fr
    ].each do |email_address|
      it "should extract UUID from #{email_address}" do
        expect(described_class.uuid_from_email_address(email_address)).to eq("b1a2-3c4f")
      end
    end
  end

  describe "#reply_address_for_rdv" do
    it "uses rdv domain reply_host_name" do
      rdv = build(:rdv)
      domain = instance_double(Domain)

      allow(rdv).to receive(:uuid).and_return("aabb-1122")
      allow(rdv).to receive(:domain).and_return(domain)
      allow(domain).to receive(:reply_host_name).and_return "reply.rdv-service-public.fr"

      expect(described_class.reply_address_for_rdv(rdv)).to eq("rdv+aabb-1122@reply.rdv-service-public.fr")
    end

    it "returns nil for a rdv whose domain reply_host_name is nil" do
      rdv = build(:rdv)
      domain = instance_double(Domain)

      allow(rdv).to receive(:domain).and_return(domain)
      allow(domain).to receive(:reply_host_name).and_return nil

      expect(described_class.reply_address_for_rdv(rdv)).to be_nil
    end
  end

  describe "#perform" do
    subject(:perform_job) { described_class.perform_now(sendinblue_payload) }

    before do
      # Set a fixed date so we can assert on dates within email body
      travel_to(Time.zone.parse("2022-05-17 16:00:00"))
    end

    let!(:user) { create(:user, email: "bene_ficiaire@lapin.fr", first_name: "Bénédicte", last_name: "Ficiaire") }
    let!(:organisation) { create(:organisation, email: "contact@departement.fr") }
    let!(:agent) { create(:agent, email: "je_suis_un_agent@departement.fr", organisations: [organisation]) }
    let(:rdv_uuid) { "8fae4d5f-4d63-4f60-b343-854d939881a3" }
    let!(:rdv) { create(:rdv, users: [user], agents: [agent], uuid: rdv_uuid, organisation:) }

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

      it "sends a notification email to the default mailbox, containing the user reply" do
        expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
        transferred_email = ActionMailer::Base.deliveries.last
        expect(transferred_email.to).to eq(["support@rdv-service-public.fr"])
        expect(transferred_email.from).to eq(["support@rdv-service-public.fr"])
        expect(transferred_email.html_part.body.to_s).to include(%(L'usager⋅e "Bénédicte Ficiaire" &lt;bene_ficiaire@lapin.fr&gt; a répondu))
        expect(transferred_email.html_part.body.to_s).to include("Je souhaite annuler mon RDV") # reply content
      end
    end

    context "when an e-mail address does not match our pattern" do
      let(:sendinblue_payload) do
        sendinblue_valid_payload.tap { |hash| hash[:Headers][:To] = "nimportequoi@reply.rdv-service-public.fr" }
      end

      it "is forwarded to default mailbox" do
        expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
        transferred_email = ActionMailer::Base.deliveries.last
        expect(transferred_email.to).to eq(["support@rdv-service-public.fr"])
        expect(transferred_email.html_part.body.to_s).to include(%(L'usager⋅e "Bénédicte Ficiaire" &lt;bene_ficiaire@lapin.fr&gt; a répondu))
      end
    end

    context "when an e-mail address matches our pattern for a demo host" do
      let(:sendinblue_payload) do
        sendinblue_valid_payload.tap { |hash| hash[:Headers][:To] = "rdv+8fae4d5f-4d63-4f60-b343-854d939881a3@reply.demo.rdv-solidarites.fr" }
      end

      it "sends a notification email to the agent" do
        expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
        transferred_email = ActionMailer::Base.deliveries.last
        expect(transferred_email.to).to eq(["je_suis_un_agent@departement.fr"])
      end
    end

    context "when several agents are linked to the RDV" do
      let!(:other_agent) { create(:agent, email: "autre@departement.fr").tap { |a| rdv.agents << a } }

      it "sends one email with all agents in the TO: field" do
        perform_job
        expect(ActionMailer::Base.deliveries.last.to).to contain_exactly("je_suis_un_agent@departement.fr", "autre@departement.fr")
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

    context "quand le RDV est avec un agent intervenant sans email" do
      let!(:agent) { create(:agent, :intervenant, first_name: "Jeanne", last_name: "Intervenante") }

      it "transfère le mail à l’adresse générique de l’organisation" do
        expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
        transferred_email = ActionMailer::Base.deliveries.last
        expect(transferred_email.to).to eq([organisation.email])
        expect(transferred_email.html_part.body.to_s).to include(%(Dans le cadre du RDV du 20 mai avec J. INTERVENANTE, l'usager⋅e Bénédicte FICIAIRE a envoyé))
      end

      context "et que l'organisation n'a pas d'adresse email" do
        let!(:organisation) { create(:organisation, email: nil) }

        it "transfère le mail à notre support" do
          expect { perform_job }.to change { ActionMailer::Base.deliveries.size }.by(1)
          transferred_email = ActionMailer::Base.deliveries.last
          expect(transferred_email.to).to eq(["support@rdv-service-public.fr"])
          expect(transferred_email.html_part.body.to_s).to include(%(L'usager⋅e "Bénédicte Ficiaire" &lt;bene_ficiaire@lapin.fr&gt; a répondu))
        end
      end
    end
  end
end
