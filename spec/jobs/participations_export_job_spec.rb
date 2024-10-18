RSpec.describe ParticipationsExportJob do
  describe "#participations_export" do
    it "provides links to download the export file" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      described_class.perform_now(agent: agent, organisation_ids: [organisation.id], options: {})

      expect { perform_enqueued_jobs }.to have_enqueued_mail(Agents::ExportMailer, :participations_export)
      expect(Export.last.file_name).to eq("export-rdvs-user-2022-09-14.xls")
    end

    it "prevents agent from exporting an org in which she does not belong" do
      agents_org = create(:organisation)
      not_agents_org = create(:organisation)
      agent = create(:agent, organisations: [agents_org])

      described_class.perform_later(agent: agent, organisation_ids: [agents_org.id, not_agents_org.id], options: {})
      expect do
        perform_enqueued_jobs
      end.to change(sentry_events, :size).by(1)
      expect(sentry_events.last.exception.values.first.value).to eq("Agent does not belong to all requested organisation(s) (RuntimeError)")
    end
  end
end
