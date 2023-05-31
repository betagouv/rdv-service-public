# frozen_string_literal: true

describe RdvsExportJob do
  stub_sentry_events

  describe "#rdv_export" do
    it "has an attachment file name which contains the current date without org ID when more than one orga" do
      organisation = create(:organisation)
      other_organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation, other_organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      described_class.perform_now(agent: agent, organisation_ids: [organisation.id, other_organisation.id], options: {})

      expect_zipped_attached_xls(expected_file_name: "export-rdv-2022-09-14.xls")
    end

    it "has an attachment which contains the current date and org ID" do
      # Le département du Var se base sur la position de chaque caractère du nom
      # de fichier pour extraire la date et l'ID d'organisation, donc
      # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.

      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      described_class.perform_now(agent: agent, organisation_ids: [organisation.id], options: {})

      expect_zipped_attached_xls(expected_file_name: "export-rdv-2022-09-14-org-#{organisation.id.to_s.rjust(6, '0')}.xls")
    end

    it "prevents agent from exporting an org in which she does not belong" do
      agents_org = create(:organisation)
      not_agents_org = create(:organisation)
      agent = create(:agent, organisations: [agents_org])

      expect do
        described_class.perform_now(agent: agent, organisation_ids: [agents_org.id, not_agents_org.id], options: {})
      end.to change(sentry_events, :size).by(1)
      expect(sentry_events.last.exception.values.first.value).to eq("Agent does not belong to all requested organisation(s) (RuntimeError)")
    end
  end

  def expect_zipped_attached_xls(expected_file_name:)
    attachment = ActionMailer::Base.deliveries.last.attachments.first
    expect(attachment.filename).to eq("#{expected_file_name}.zip")
    Zip::File.open_buffer(attachment.body.raw_source) do |zip_file|
      expect(zip_file.map(&:name)).to eq([expected_file_name])
    end
  end
end
