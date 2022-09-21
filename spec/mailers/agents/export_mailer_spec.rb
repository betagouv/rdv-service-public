# frozen_string_literal: true

describe Agents::ExportMailer do
  describe "#rdv_export" do
    subject(:rdv_export) { described_class.rdv_export(agent, organisation, {}) }

    let(:organisation) { create(:organisation, id: 666) }
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    it "has an attachment which contains the current date and org ID" do
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))
      expect(rdv_export.attachments.first.filename).to eq("export-rdv-2022-09-14-org-000666.xls")
    end
  end
end
