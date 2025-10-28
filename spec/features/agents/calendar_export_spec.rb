RSpec.describe "Agents can export their calendar to other tools, such as Outlook or Google calendar" do
  it "allows resetting the link and shows the agent's name in the link to make it clear that it's their info" do
    uid = "37b24280-7015-4a8a-b752-907e33171106"
    allow(SecureRandom).to receive(:uuid).and_return(uid)
    organisation = create(:organisation)
    create(:agent, admin_role_in_organisations: [organisation])
    agent = create(:agent, basic_role_in_organisations: [organisation], first_name: "Rémi", last_name: "NOM D'AGENT")
    login_as(agent, scope: :agent)

    visit agents_calendar_sync_webcal_sync_path

    webcal_url = "http://#{Capybara.server_host}:#{Capybara.server_port}/calendrier/remi-nom-d-agent-#{uid}.ics"

    expect(page.find('input[name="calendar_url"]').value).to eq webcal_url

    visit webcal_url
    expect(page).to have_content "BEGIN:VCALENDAR"

    visit agents_calendar_sync_webcal_sync_path

    second_uid = "f7d1f2dd-0911-4f6e-b319-73a982429fd1"
    allow(SecureRandom).to receive(:uuid).and_return(second_uid)

    click_button "Réinitialiser"

    visit webcal_url
    expect(status_code).to eq 404
  end

  describe "consultation du calendrier par lien ICS" do
    let(:organisation) { create(:organisation, id: 123_000) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation], calendar_uid:, first_name: "Marceau", last_name: "COLIN") }
    let(:motif) { create(:motif, name: "Accompagnement individuel", organisation: organisation) }
    let(:motif_collectif) { create(:motif, :collectif, name: "Atelier collectif", organisation: organisation) }

    context "quand l’agent n’a pas de UID de calendrier" do
      let(:calendar_uid) { nil }

      it "n’autoriser pas la consultation" do
        create(:agent, calendar_uid: nil)
        webcal_url = "http://#{Capybara.server_host}:#{Capybara.server_port}/calendrier/.ics"

        expect { visit webcal_url }.to raise_error(ActionController::RoutingError)
      end
    end

    context "quand l’agent à un UID de calendrier" do
      let(:calendar_uid) { SecureRandom.uuid }

      before do
        travel_to(Time.zone.local(2022, 7, 8))
        create(:rdv, motif: motif, agents: [agent], status: "unknown", starts_at: 1.day.from_now, uuid: "e0a8dbac-d06c-4d18-98c6-a48f47fddd4c", organisation:, id: 456_000)
      end

      it "displays rdvs in the proper format for calendars, without including personal information" do
        create(:rdv, motif: motif, agents: [agent], status: "revoked", starts_at: 2.days.from_now, uuid: "749336ce-eaca-40a3-8c28-246ed8d18849", organisation:, id: 789_000)
        create(:rdv, motif: motif_collectif, agents: [agent], status: "unknown", starts_at: 3.days.from_now, uuid: "abb701a5-381a-4fae-9157-129b5843834c", organisation:, id: 123_123,
                     max_participants_count: 5)

        visit ics_calendar_path(agent.calendar_uid, format: :ics)

        expect(page.body.gsub("\r\n", "\n")).to eq Rails.root.join("spec/support/calendar.ics").read
      end

      it %(ne plante pas durant le passage à l'heure d'hiver, où "2h30" du mat' devient ambigu) do
        travel_to(Time.zone.local(2025, 10, 26) + 2.hours + 30.minutes)
        visit ics_calendar_path(agent.calendar_uid, format: :ics)
        expect(page.body).to include("TZID:Europe/Paris")
        expect(page.body).to include("DTSTART:20251026T020000")
      end

      context "lorsque l’agent est dans une organisation ayant un fuseau horaire différent de celui de la métropole" do
        let(:organisation) { create(:organisation, time_zone: "America/Guadeloupe", id: 123_000) }

        it "renvoie le bon VTIMEZONE dans le fichier ICS" do
          visit ics_calendar_path(agent.calendar_uid, format: :ics)

          expect(page.body.gsub("\r\n", "\n")).to eq Rails.root.join("spec/support/calendar_guadeloupe.ics").read
        end
      end
    end
  end
end
