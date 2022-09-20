# frozen_string_literal: true

# This specs checks that the ICS attachments are added correctly.
# It was after a bug was discovered: several copies of the ICS file were present.
describe IcsMultipartAttached, type: :mailer do
  let(:agent) { create(:agent, email: "bob@demo.rdv-solidarites.fr") }
  let(:plage_ouverture) { create :plage_ouverture, agent: agent }

  describe "when creating event" do
    it "email parts should include application/ics and text/calendar" do
      mail = Agents::PlageOuvertureMailer.with(plage_ouverture: plage_ouverture).plage_ouverture_created

      expect(mail.attachments.size).to eq(1)

      expected_parts_order = [
        "text/html; charset=UTF-8",
        "application/ics",
        "text/calendar; charset=utf-8; method=PUBLISH",
      ]
      expect(mail.all_parts.map(&:content_type)).to eq(expected_parts_order)
    end
  end

  describe "when updating event" do
    it "email parts should include application/ics and text/calendar" do
      mail = Agents::PlageOuvertureMailer.with(plage_ouverture: plage_ouverture).plage_ouverture_updated

      expect(mail.attachments.size).to eq(1)

      expected_parts_order = [
        "text/html; charset=UTF-8",
        "application/ics",
        "text/calendar; charset=utf-8; method=PUBLISH",
      ]
      expect(mail.all_parts.map(&:content_type)).to eq(expected_parts_order)
    end
  end

  describe "when deleting event" do
    it "email parts should include application/ics and text/calendar" do
      mail = Agents::PlageOuvertureMailer.with(plage_ouverture: plage_ouverture).plage_ouverture_destroyed

      expect(mail.attachments.size).to eq(1)

      expected_parts_order = [
        "text/html; charset=UTF-8",
        "application/ics",
        "text/calendar; charset=utf-8; method=CANCEL",
      ]
      expect(mail.all_parts.map(&:content_type)).to eq(expected_parts_order)
    end
  end
end
