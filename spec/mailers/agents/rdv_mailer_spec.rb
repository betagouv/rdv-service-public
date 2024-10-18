RSpec.describe Agents::RdvMailer, type: :mailer do
  describe "#rdv_created" do
    let(:agent) { build(:agent) }
    let(:t) { Time.zone.parse("2020-03-01 10:20") }
    let(:mail) { described_class.with(rdv: rdv, agent: agent).rdv_created }
    let(:rdv) { create(:rdv, starts_at: t + 2.hours, agents: [agent]) }

    before { travel_to(t) }

    it "renders the headers" do
      expect(mail[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
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
          expect(mail.html_part.body.to_s).to include(%(src="/logo_solidarites.png))
          expect(mail.html_part.body.to_s).to include("Voir sur RDV Solidarités")
          expect(mail.html_part.body.to_s).to include(%(href="http://www.rdv-solidarites-test.localhost))
        end
      end

      context "when agent's service is on a different domain" do
        let(:agent) { build(:agent, service: build(:service, :conseiller_numerique)) }

        before do
          allow(agent).to receive(:domain).and_return(Domain::RDV_AIDE_NUMERIQUE)
        end

        it "works" do
          expect(mail.html_part.body.to_s).to include(%(src="/logo_aide_numerique.png))
          expect(mail.html_part.body.to_s).to include("Voir sur RDV Aide Numérique")
          expect(mail.html_part.body.to_s).to include(%(href="http://www.rdv-aide-numerique-test.localhost/))
        end
      end
    end
  end

  describe "#rdv_updated" do
    let(:previous_starting_time) { 2.days.from_now }
    let(:new_starting_time) { 3.days.from_now }
    let(:new_lieu) { create(:lieu, name: "Stade de France", address: "rue du Stade, Paris, 75016") }
    let(:previous_lieu) { create(:lieu, name: "MJC Aix", address: "rue du Previous, Paris, 75016") }
    let(:rdv) { create(:rdv, lieu: new_lieu, starts_at: new_starting_time) }
    let(:agent) { rdv.agents.first }
    let(:token) { "12345" }

    before { travel_to(Time.zone.parse("2022-08-24 09:00:00")) }

    it "renders the headers" do
      mail = described_class.with(rdv: rdv, agent: agent, author: agent).rdv_updated(old_starts_at: previous_starting_time, lieu_id: nil)
      expect(mail[:from].to_s).to eq(%("RDV Solidarités" <support@rdv-solidarites.fr>))
      expect(mail.to).to eq([agent.email])
    end

    it "indicates the previous and current values" do
      mail = described_class.with(rdv: rdv, agent: agent, author: agent)
        .rdv_updated(old_starts_at: previous_starting_time, lieu_id: previous_lieu.id)

      previous_details = "Un de vos RDV qui devait avoir lieu le 26 août à 09:00 à l&#39;adresse MJC Aix (rue du Previous, Paris, 75016) a été modifié"
      expect(mail.html_part.body.to_s).to include(previous_details)

      # new details
      expect(mail.html_part.body.to_s).to include("samedi 27 août 2022 à 09h00")
      expect(mail.html_part.body.to_s).to include("Stade de France (rue du Stade, Paris, 75016)")
    end

    it "works when no lieu_id is passed" do
      mail = described_class.with(rdv: rdv, agent: agent, author: agent)
        .rdv_updated(old_starts_at: previous_starting_time, lieu_id: nil)

      previous_details = "Un de vos RDV qui devait avoir lieu le 26 août à 09:00 a été modifié"
      expect(mail.html_part.body.to_s).to include(previous_details)
    end
  end
end
