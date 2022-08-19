# frozen_string_literal: true

RSpec.describe Agents::RdvMailer, type: :mailer do
  describe "#rdv_created" do
    let(:agent) { build(:agent) }
    let(:t) { DateTime.parse("2020-03-01 10:20") }
    let(:mail) { described_class.with(rdv: rdv, agent: agent).rdv_created }
    let(:rdv) { create(:rdv, starts_at: t + 2.hours, agents: [agent]) }

    before { travel_to(t) }

    it "renders the headers" do
      expect(mail.to).to eq([agent.email])
    end

    context "in 2 hours" do
      let(:rdv) { create(:rdv, starts_at: t + 10.minutes, agents: [agent]) }

      it "has a correct subject" do
        expect(mail.subject).to eq("Nouveau RDV ajouté sur votre agenda RDV Solidarités pour aujourd’hui")
      end
    end

    context "tomorrow" do
      let(:rdv) { create(:rdv, starts_at: t + 1.day, agents: [agent]) }

      it "has a correct subject" do
        expect(mail.subject).to eq("Nouveau RDV ajouté sur votre agenda RDV Solidarités pour demain")
      end
    end

    describe "using the agent domain's branding" do
      context "when agent's service is not conseiller_numerique" do
        let(:agent) { build(:agent, service: build(:service, :social)) }

        it "works" do
          expect(mail.html_part.body.to_s).to include(%(src="/logo.png))
          expect(mail.html_part.body.to_s).to include("Voir sur RDV Solidarités")
          expect(mail.html_part.body.to_s).to include(%(href="http://rdv-solidarites-test.localhost))
        end
      end

      context "when agent's service is on a different domain" do
        let(:agent) { build(:agent, service: build(:service, :conseiller_numerique)) }

        before do
          allow(agent).to receive(:domain).and_return(Domain::RDV_INCLUSION_NUMERIQUE)
        end

        it "works" do
          expect(mail.html_part.body.to_s).to include(%(src="/logo_inclusion_numerique.png))
          expect(mail.html_part.body.to_s).to include("Voir sur RDV Inclusion Numérique")
          expect(mail.html_part.body.to_s).to include(%(href="http://rdv-inclusion-numerique-test.localhost/))
        end
      end
    end
  end
end
