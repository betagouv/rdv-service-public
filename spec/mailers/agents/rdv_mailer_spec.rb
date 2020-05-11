RSpec.describe Agents::RdvMailer, type: :mailer do
  describe "#rdv_starting_soon_created" do
    let(:agent) { build(:agent) }
    let(:t) { DateTime.parse("2020-03-01 10:20") }
    let(:mail) { Agents::RdvMailer.rdv_starting_soon_created(rdv, agent) }
    let(:rdv) { create(:rdv, starts_at: t + 2.hours, agents: [agent]) }

    before { travel_to(t) }
    after { travel_back }

    it "renders the headers" do
      expect(mail.to).to eq([agent.email])
    end

    context "in 2 hours" do
      let(:rdv) { create(:rdv, starts_at: t + 10.minutes, agents: [agent]) }

      it "has a correct subject" do
        expect(mail.subject).to eq("Nouveau RDV ajouté sur votre agenda rdv-solidarités pour aujourd'hui")
      end
    end

    context "tomorrow" do
      let(:rdv) { create(:rdv, starts_at: t + 1.day, agents: [agent]) }

      it "has a correct subject" do
        expect(mail.subject).to eq("Nouveau RDV ajouté sur votre agenda rdv-solidarités pour demain")
      end
    end
  end
end
