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
      agent = create(:agent, admin_role_in_organisations: [agents_org])
      agents_rdv = create(:rdv, organisation: agents_org)
      not_agents_org = create(:organisation)
      _not_agents_rdv = create(:rdv, organisation: not_agents_org)

      job = described_class.new
      job.perform(agent: agent, options: { scoped_organisation_ids: [agents_org.id, not_agents_org.id] })
      expect(job.rdvs.map(&:id)).to contain_exactly(agents_rdv.id)
    end
  end
end
