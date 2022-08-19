# frozen_string_literal: true

describe Agents::PlageOuvertureMailer, type: :mailer do
  { created: "créée", updated: "modifiée", destroyed: "supprimée" }.each do |action, verb|
    context "when #{action}" do
      let(:agent) { create(:agent, email: "bob@demo.rdv-solidarites.fr") }
      let(:plage_ouverture) { create :plage_ouverture, agent: agent }

      it "mail to plage ouverture's agent" do
        mail = described_class.with(plage_ouverture: plage_ouverture).send("plage_ouverture_#{action}")
        expect(mail.to).to eq(["bob@demo.rdv-solidarites.fr"])
      end

      it "have a good subject" do
        mail = described_class.with(plage_ouverture: plage_ouverture).send("plage_ouverture_#{action}")
        expect(mail.subject).to eq("RDV Solidarités - Plage d’ouverture #{verb} - #{plage_ouverture.title}")
      end

      it "has a ICS file join with UID" do
        mail = described_class.with(plage_ouverture: plage_ouverture).send("plage_ouverture_#{action}")
        cal = mail.find_first_mime_type("text/calendar")
        expect(cal.decoded).to match("UID:plage_ouverture_#{plage_ouverture.id}@RDV Solidarités")
      end

      describe "using the agent domain's branding" do
        context "when agent's service is not conseiller_numerique" do
          let(:agent) { build(:agent, service: build(:service, :social)) }

          it "works" do
            mail = described_class.with(plage_ouverture: plage_ouverture).send("plage_ouverture_#{action}")
            expect(mail.subject).to start_with("RDV Solidarités - Plage d’ouverture")
            expect(mail.html_part.body.to_s).to include(%(src="/logo.png))
            expect(mail.html_part.body.to_s).to include("Voir sur RDV Solidarités") unless action == :destroyed
            expect(mail.html_part.body.to_s).to include(%(href="http://rdv-solidarites-test.localhost/))
          end
        end

        context "when agent is on a different domain" do
          let(:agent) { build(:agent, service: build(:service, :conseiller_numerique)) }

          before do
            allow(agent).to receive(:domain).and_return(Domain::RDV_INCLUSION_NUMERIQUE)
          end

          it "works" do
            mail = described_class.with(plage_ouverture: plage_ouverture).send("plage_ouverture_#{action}")
            expect(mail.subject).to start_with("RDV Inclusion Numérique - Plage d’ouverture")
            expect(mail.html_part.body.to_s).to include(%(src="/logo_inclusion_numerique.png))
            expect(mail.html_part.body.to_s).to include("Voir sur RDV Inclusion Numérique") unless action == :destroyed
            expect(mail.html_part.body.to_s).to include(%(href="http://rdv-inclusion-numerique-test.localhost/))
          end
        end
      end
    end
  end

  describe "#plage_ouverture_destroyed" do
    let(:plage_ouverture) { create :plage_ouverture }

    it "have a STATUS:CANCELLED in ICS file joined" do
      mail = described_class.with(plage_ouverture: plage_ouverture).send("plage_ouverture_destroyed")
      cal = mail.find_first_mime_type("text/calendar")
      expect(cal.decoded).to match("STATUS:CANCELLED")
    end
  end
end
