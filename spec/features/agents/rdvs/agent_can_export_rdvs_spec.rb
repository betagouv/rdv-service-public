RSpec.describe "agent can export RDVs" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before do
    travel_to(Time.zone.parse("2022-09-14 09:00:00"))
    login_as(agent, scope: :agent)
  end

  it "displays export list" do
    create(:rdv, organisation: organisation)
    visit admin_organisation_rdvs_url(organisation)
    click_on "Exporter le RDV en XLS"
    perform_enqueued_jobs

    login_as(agent, scope: :agent)
    visit agents_exports_path
    expect(page).to have_content("En création")

    perform_enqueued_jobs
    visit agents_exports_path
    expect(page).not_to have_content("En création")
    expect(page).to have_content("Télécharger")
  end

  it "exports by RDV" do
    rdvs = 4.times.map do |i|
      create(:rdv, organisation: organisation, starts_at: 3.days.from_now + i.hours)
    end

    visit admin_organisation_rdvs_url(organisation)
    perform_enqueued_jobs do
      click_on "Exporter les 4 RDV en XLS"
    end

    open_email(agent.email)
    expect(current_email.subject).to eq("Export des RDVs du 14/09/2022 à 09:00")

    login_as(agent, scope: :agent) # Il semble nécessaire d'appeler ce helper encore une fois ici
    current_email.click_link("la page des exports")
    expect(page).to have_current_path("/agents/exports")
    click_on "Télécharger"

    expected_file_name = "export-rdv-2022-09-14-org-#{organisation.id.to_s.rjust(6, '0')}.xls"
    expect(response_headers["Content-Disposition"]).to include(expected_file_name)

    book = Spreadsheet.open(StringIO.new(page.body))
    expect(book.worksheets[0].rows.size).to eq(5)
    expect(book.worksheets[0].row(0)[11]).to eq("professionnel.le(s)")

    rdvs = rdvs.sort_by(&:starts_at).reverse # les exports sont ordonnés par `starts_at DESC`
    4.times do |i|
      expect(book.worksheets[0].row(i + 1)[7]).to eq(rdvs[i].motif.name)
      expect(book.worksheets[0].row(i + 1)[11]).to eq(rdvs[i].agents.first.full_name)
    end
  end

  it "exports by participation" do
    rdvs = create_list(:rdv, 4, organisation: organisation)
    visit admin_organisation_rdvs_url(organisation)
    perform_enqueued_jobs do
      click_on "Exporter les RDV par usager en XLS"
    end

    open_email(agent.email)
    expect(current_email.subject).to eq("Export des RDVs par usager du 14/09/2022 à 09:00")

    login_as(agent, scope: :agent) # Il semble nécessaire d'appeler ce helper encore une fois ici
    current_email.click_link("la page des exports")
    expect(page).to have_current_path("/agents/exports")
    click_on "Télécharger"

    expect(response_headers["Content-Disposition"]).to include("export-rdvs-user-2022-09-14.xls")

    book = Spreadsheet.open(StringIO.new(page.body))
    expect(book.worksheets[0].rows.size).to eq(5)
    expect(book.worksheets[0].row(0)[1]).to eq("rdv_id")
    rdv_ids = 4.times.map { book.worksheets[0].row(_1 + 1)[1] }
    expect(rdv_ids).to match_array(rdvs.map(&:id))
  end

  describe "the whole export process" do
    it "has an attachment file name which contains the current date without org ID when more than one orga" do
      other_organisation = create(:organisation)
      agent.roles.create!(organisation: other_organisation)
      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      RdvsExportJob.perform_now(agent: agent, organisation_ids: [organisation.id, other_organisation.id], options: {})

      expect { perform_enqueued_jobs }.to have_enqueued_mail(Agents::ExportMailer, :export_ready)
      expect(Export.last.file_name).to eq("export-rdv-2022-09-14.xls")
    end

    it "has an attachment which contains the current date and org ID" do
      # Le département du Var se base sur la position de chaque caractère du nom
      # de fichier pour extraire la date et l'ID d'organisation, donc
      # si on modifie le fichier il faut soit les prévenir soit ajouter à la fin.

      travel_to(Time.zone.parse("2022-09-14 09:00:00"))

      RdvsExportJob.perform_now(agent: agent, organisation_ids: [organisation.id], options: {})

      # Perform batch of jobs and callback job
      expect { perform_enqueued_jobs }.to have_enqueued_mail
      # Deliver email
      perform_enqueued_jobs

      expect(Export.last.file_name).to eq("export-rdv-2022-09-14-org-#{organisation.id.to_s.rjust(6, '0')}.xls")
      email = first_email_sent_to(agent.email)
      expect(email.html_part.body.to_s).to include("Votre export est prêt")
    end

    it "prevents agent from exporting an org in which she does not belong" do
      not_agents_org = create(:organisation)

      expect do
        RdvsExportJob.perform_now(agent: agent, organisation_ids: [organisation.id, not_agents_org.id], options: {})
      end.to change(sentry_events, :size).by(1)
      expect(sentry_events.last.exception.values.first.value).to eq("Agent does not belong to all requested organisation(s) (RuntimeError)")
    end
  end
end
