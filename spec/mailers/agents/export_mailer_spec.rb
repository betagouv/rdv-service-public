# frozen_string_literal: true

describe Agents::ExportMailer do
  def expect_zipped_attached_xls(attachment, expected_file_name:)
    expect(attachment.filename).to eq("#{expected_file_name}.zip")
    Zip::File.open_buffer(attachment.body.raw_source) do |zip_file|
      expect(zip_file.map(&:name)).to eq([expected_file_name])
    end
  end

  describe "#rdv_export" do
    it "has an attachment file name which contains the current date without org ID when more than one orga" do
      organisation = create(:organisation)
      other_organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation, other_organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      rdv_export = described_class.rdv_export(agent, [organisation.id, other_organisation.id], {})

      expect_zipped_attached_xls(rdv_export.attachments.first, expected_file_name: "export-rdv-2022-09-14.xls")
    end

    it "has an attachment which contains the current date and org ID" do
      # Le département du Var se base sur la position de chaque caractère du nom
      # de fichier pour extraire la date et l'ID d'organisation, donc
      # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.

      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      rdv_export = described_class.rdv_export(agent, [organisation.id], {})

      expected_file_name = "export-rdv-2022-09-14-org-#{organisation.id.to_s.rjust(6, '0')}.xls"
      expect_zipped_attached_xls(rdv_export.attachments.first, expected_file_name: expected_file_name)
    end

    it "prevents agent from exporting an org in which she does not belong" do
      agents_org = create(:organisation)
      not_agents_org = create(:organisation)
      agent = create(:agent, organisations: [agents_org])

      rdv_export = described_class.rdv_export(agent, [agents_org.id, not_agents_org.id], {})

      expect { rdv_export.deliver_now }.to raise_error("Agent does not belong to all requested organisation(s)")
    end
  end

  describe "#rdvs_users_export" do
    it "has an attachment which contains the current date" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      rdvs_users_export = described_class.rdvs_users_export(agent, [organisation.id], {})

      expect_zipped_attached_xls(rdvs_users_export.attachments.first, expected_file_name: "export-rdvs-user-2022-09-14.xls")
    end

    it "prevents agent from exporting an org in which she does not belong" do
      agents_org = create(:organisation)
      not_agents_org = create(:organisation)
      agent = create(:agent, organisations: [agents_org])

      rdvs_users_export = described_class.rdvs_users_export(agent, [agents_org.id, not_agents_org.id], {})

      expect { rdvs_users_export.deliver_now }.to raise_error("Agent does not belong to all requested organisation(s)")
    end
  end
end
