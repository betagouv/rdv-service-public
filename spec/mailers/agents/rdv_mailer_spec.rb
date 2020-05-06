RSpec.describe Agents::RdvMailer, type: :mailer do
  shared_examples "mail with ICS" do
    it "contains the ics" do
      expect(mail.body.encoded).to match("UID:#{rdv.uuid}")
      expect(mail.body.encoded).to match("STATUS:CANCELLED") if rdv.cancelled?
    end
  end

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
      let(:rdv) { create(:rdv, starts_at: t + 2.hours, agents: [agent]) }

      it "has a correct subject" do
        expect(mail.subject).to eq("Nouveau RDV dans environ 2 heures ajouté à votre agenda")
      end
    end

    context "tomorrow" do
      let(:rdv) { create(:rdv, starts_at: t + 1.day, agents: [agent]) }

      it "has a correct subject" do
        expect(mail.subject).to eq("Nouveau RDV demain ajouté à votre agenda")
      end
    end

    it_behaves_like "mail with ICS"
  end
end
