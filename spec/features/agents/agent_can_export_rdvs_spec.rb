RSpec.describe "agent can export RDVs" do
  let!(:organisation) { organisations(:default_org) }
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
end
