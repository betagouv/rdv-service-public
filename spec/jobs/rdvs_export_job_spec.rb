RSpec.describe RdvsExportJob do
  describe "#rdv_export" do
    it "has an attachment file name which contains the current date without org ID when more than one orga" do
      organisation = create(:organisation)
      other_organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation, other_organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      described_class.perform_now(agent: agent, options: { scoped_organisation_ids: [organisation.id, other_organisation.id] })

      expect { perform_enqueued_jobs }.to have_enqueued_mail(Agents::ExportMailer, :rdv_export)
      expect(Export.last.file_name).to eq("export-rdv-2022-09-14.xls")
    end

    it "has an attachment which contains the current date and org ID" do
      # Le département du Var se base sur la position de chaque caractère du nom
      # de fichier pour extraire la date et l'ID d'organisation, donc
      # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.

      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      described_class.perform_now(agent: agent, options: { scoped_organisation_ids: [organisation.id] })

      # Perform batch of jobs and callback job
      expect { perform_enqueued_jobs }.to have_enqueued_mail
      # Deliver email
      perform_enqueued_jobs

      expect(Export.last.file_name).to eq("export-rdv-2022-09-14-org-#{organisation.id.to_s.rjust(6, '0')}.xls")
      email = email_sent_to(agent.email)
      expect(email.html_part.body.to_s).to include("Votre export est prêt")
    end

    it "does not export rdvs from an org in which agent does not belong" do
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
