# frozen_string_literal: true

describe RdvsUsersExportJob do
  def expect_zipped_attached_xls(attachment, expected_file_name:)
    expect(attachment.filename).to eq("#{expected_file_name}.zip")
    Zip::File.open_buffer(attachment.body.raw_source) do |zip_file|
      expect(zip_file.map(&:name)).to eq([expected_file_name])
    end
  end

  stub_sentry_events

  describe "#rdvs_users_export" do
    it "has an attachment which contains the current date" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      rdvs_users_export = described_class.perform_now(agent, [organisation.id], {})

      expect_zipped_attached_xls(rdvs_users_export.attachments.first, expected_file_name: "export-rdvs-user-2022-09-14.xls")
    end

    it "prevents agent from exporting an org in which she does not belong" do
      agents_org = create(:organisation)
      not_agents_org = create(:organisation)
      agent = create(:agent, organisations: [agents_org])

      expect do
        described_class.perform_now(agent, [agents_org.id, not_agents_org.id], {})
      end.to change(sentry_events, :size).by(1)
      expect(sentry_events.last.exception.values.first.value).to eq("Agent does not belong to all requested organisation(s) (RuntimeError)")
    end
  end
end
