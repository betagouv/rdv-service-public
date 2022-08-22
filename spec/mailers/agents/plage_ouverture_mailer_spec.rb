# frozen_string_literal: true

describe Agents::PlageOuvertureMailer, type: :mailer do
  { created: "créée", updated: "modifiée", destroyed: "supprimée" }.each do |action, verb|
    context "when #{action}" do
      let(:plage_ouverture) { create :plage_ouverture, agent: create(:agent, email: "bob@demo.rdv-solidarites.fr") }

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
