RSpec.describe ParticipationsExportJob do
  describe "#participations_export" do
    it "provides links to download the export file" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      described_class.perform_now(agent: agent, organisation_ids: [organisation.id], options: {})

      expect { perform_enqueued_jobs }.to have_enqueued_mail(Agents::ExportMailer, :export_ready)
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

    it "n'exporte que les participations des RDV que l'agent est autorisé à voir" do
      territory = create(:territory)
      organisation = create(:organisation, territory:)
      user = create(:user, organisations: [organisation])

      # on crée un premier RDV pour l'agent qui va exporter
      service = create(:service)
      agent = create(:agent, basic_role_in_organisations: [organisation], service:)
      motif = create(:motif, organisation:, service:)
      rdv = create(:rdv, organisation:, motif:, agents: [agent], users: [user])

      # on crée un RDV pour le même usager mais avec un agent d'un autre service
      service2 = create(:service)
      agent2 = create(:agent, basic_role_in_organisations: [organisation], service: service2)
      motif2 = create(:motif, organisation:, service: service2)
      _rdv2 = create(:rdv, organisation:, motif: motif2, agents: [agent2], users: [user])

      expect(ParticipationsExportPageJob).to receive(:perform_later).with(
        a_collection_containing_exactly(rdv.participations.first.id), # seulement rdv, pas rdv2
        any_args
      )
      described_class.perform_now(agent:, organisation_ids: [organisation.id], options: {})
    end
  end
end
