RSpec.describe "agent can export RDVs" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:rdv) { create(:rdv, organisation: organisation) }

  before do
    travel_to(Time.zone.parse("2022-09-14 09:00:00"))
    login_as(agent, scope: :agent)
  end

  it "exports by RDV" do
    visit admin_organisation_rdvs_url(organisation, agent)
    perform_enqueued_jobs do
      click_on "Exporter les 1 RDVs en XLS"
    end

    open_email(agent.email)
    expect(current_email.subject).to eq("Export des RDVs du 14/09/2022 à 09:00")
    expect(current_email).to have_content("Votre export est prêt, vous pouvez le télécharger ici")
    expect(current_email).to have_content("Retrouvez tous vos exports ici")
    expect(current_email.body).to include('<a href="http://www.rdv-solidarites-test.localhost/agents/exports')

    login_as(agent, scope: :agent) # Il semble nécessaire d'appeler ce helper encore une fois ici
    export = Export.last

    expected_file_name = "export-rdv-2022-09-14-org-#{organisation.id.to_s.rjust(6, '0')}.xls"
    current_email.click_link(expected_file_name)
    expect(page).to have_current_path("/agents/exports/#{export.id}")
    click_on expected_file_name
    book = Spreadsheet.open(StringIO.new(page.body))
    expect(book.worksheets[0].row(0)[11]).to eq("professionnel.le(s)")
    expect(book.worksheets[0].row(1)[11]).to eq(rdv.agents.first.full_name)
  end

  it "exports by participation" do
    visit admin_organisation_rdvs_url(organisation, agent)
    perform_enqueued_jobs do
      click_on "Exporter les RDVs par usager en XLS"
    end

    open_email(agent.email)
    expect(current_email.subject).to eq("Export des RDVs par usager du 14/09/2022 à 09:00")
    expect(current_email).to have_content("Votre export est prêt, vous pouvez le télécharger ici")
    expect(current_email).to have_content("Retrouvez tous vos exports ici")
    expect(current_email.body).to include('<a href="http://www.rdv-solidarites-test.localhost/agents/exports')

    login_as(agent, scope: :agent) # Il semble nécessaire d'appeler ce helper encore une fois ici
    export = Export.last

    current_email.click_link("export-rdvs-user-2022-09-14.xls")
    expect(page).to have_current_path("/agents/exports/#{export.id}")
    click_on "export-rdvs-user-2022-09-14.xls"
    book = Spreadsheet.open(StringIO.new(page.body))
    expect(book.worksheets[0].row(0)[1]).to eq("rdv_id")
    expect(book.worksheets[0].row(1)[1]).to eq(rdv.id)
  end
end
