RSpec.describe "agent can setup CalDAV" do
  let!(:agent) { create(:agent) }

  it "works" do
    # On stubbe la génération aléatoire d'ID de l'événement de test pour que la cassette matche
    allow(CaldavUtils).to receive(:generate_test_event_uid).and_return("rdvsp-connection-test-3121bd24-5bda-4bcb-985f-0b96049031de")

    VCR.use_cassette("caldav/setup/full_setup_ok_la_suite") do
      login_as(agent, scope: :agent)
      visit agents_calendar_sync_path
      click_on "Connecter mon agenda via CalDAV"
      fill_in :caldav_username, with: "francois.ferrandis.ext@beta.gouv.fr"
      fill_in :caldav_password, with: "onhs-eyjw-resn-zxdt"
      fill_in :caldav_agenda_url, with: "https://messagerie.numerique.gouv.fr/dav/caldav/Y2FsOi8vMC8yMjg0OA"
      fill_in :caldav_calendar_name, with: "Mon agenda externe"
      click_on "Enregistrer"
      choose "test sync"
      click_on "Valider"

      expect(page).to have_content("Synchronisation active")
      expect(page).to have_content("Nom d'utilisateur\nfrancois.ferrandis.ext@beta.gouv.fr")
      expect(page).to have_content("Nom d’affichage\nMon agenda externe")

      expected_attrs = {
        caldav_agenda_url: "https://messagerie.numerique.gouv.fr/dav/caldav/Y2FsOi8vMC8yMjg0OA/",
        caldav_calendar_name: "Mon agenda externe",
        caldav_calendar_color: "#34393A",
      }
      expect(agent.reload.caldav_config).to have_attributes(expected_attrs)
    end
  end
end
