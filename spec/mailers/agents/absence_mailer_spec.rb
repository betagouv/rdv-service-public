# frozen_string_literal: true

describe Agents::AbsenceMailer, type: :mailer do
  { created: "créée", updated: "modifiée", destroyed: "supprimée" }.each do |action, verb|
    context "when #{action}" do
      let(:agent) { create(:agent, email: "bob@demo.rdv-solidarites.fr", basic_role_in_organisations: [create(:organisation)]) }
      let(:absence) { create :absence, agent: agent }

      it "mail to absence's agent" do
        mail = described_class.with(absence: absence).send("absence_#{action}")
        expect(mail[:from].to_s).to eq(%("RDV Solidarités" <secretariat-auto@rdv-solidarites.fr>))
        expect(mail.to).to eq(["bob@demo.rdv-solidarites.fr"])
      end

      it "have a good subject" do
        mail = described_class.with(absence: absence).send("absence_#{action}")
        expect(mail.subject).to eq("RDV Solidarités - Indisponibilité #{verb} - #{absence.title}")
      end

      it "has a ICS file join with UID" do
        mail = described_class.with(absence: absence).send("absence_#{action}")
        cal = mail.find_first_mime_type("text/calendar")
        expect(cal.decoded).to match("UID:absence_#{absence.id}@RDV Solidarités")
      end

      describe "using the agent domain's branding" do
        context "when agent belongs to an organisation with new_domain_beta=false" do
          before { agent.organisations.first.update!(new_domain_beta: false) }

          it "works" do
            mail = described_class.with(absence: absence).send("absence_#{action}")
            expect(mail.subject).to start_with("RDV Solidarités - Indisponibilité")
            expect(mail.html_part.body.to_s).to include(%(src="/logo_solidarites.png))
            expect(mail.html_part.body.to_s).to include("Voir sur RDV Solidarités") unless action == :destroyed
            expect(mail.html_part.body.to_s).to include(%(href="http://www.rdv-solidarites-test.localhost/))
          end
        end

        context "when agent belongs to an organisation with new_domain_beta=true" do
          before { agent.organisations.first.update!(new_domain_beta: false) }

          before do
            allow(agent).to receive(:domain).and_return(Domain::RDV_AIDE_NUMERIQUE)
          end

          it "works" do
            mail = described_class.with(absence: absence).send("absence_#{action}")
            expect(mail[:from].to_s).to eq(%("RDV Aide Numérique" <secretariat-auto@rdv-solidarites.fr>))
            expect(mail.subject).to start_with("RDV Aide Numérique - Indisponibilité")
            expect(mail.html_part.body.to_s).to include(%(src="/logo_aide_numerique.png))
            expect(mail.html_part.body.to_s).to include("Voir sur RDV Aide Numérique") unless action == :destroyed
            expect(mail.html_part.body.to_s).to include(%(href="http://www.rdv-aide-numerique-test.localhost/))
          end
        end
      end
    end
  end

  describe "#absence_destroyed" do
    let(:absence) { create :absence }

    it "have a STATUS:CANCELLED in ICS file joined" do
      mail = described_class.with(absence: absence).absence_destroyed
      cal = mail.find_first_mime_type("text/calendar")
      expect(cal.decoded).to match("STATUS:CANCELLED")
    end
  end
end
