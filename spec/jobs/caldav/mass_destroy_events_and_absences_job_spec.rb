RSpec.describe Caldav::MassDestroyEventsAndAbsencesJob do
  let(:agent) { create(:agent, :with_caldav_config) }
  let(:agents_rdv) { create(:agents_rdv, agent:, caldav_url: "https://caldav.example.com/event.ics") }
  let(:caldav_client) { instance_double(Calendav::Client, events: caldav_events) }
  let(:caldav_events) { instance_double(Calendav::Clients::EventsClient) }

  before do
    allow_any_instance_of(CaldavConfig).to receive(:caldav_client).and_return(caldav_client) # rubocop:disable RSpec/AnyInstance
    allow(caldav_events).to receive(:delete)
    agents_rdv
  end

  it "supprime les événements caldav des agents_rdv" do
    expect(caldav_events).to receive(:delete).with("https://caldav.example.com/event.ics")
    described_class.new.perform(agent)
  end

  it "vide le caldav_url des agents_rdv" do
    described_class.new.perform(agent)
    expect(agents_rdv.reload.caldav_url).to be_nil
  end

  it "supprime les external_calendar_events et la config caldav de l'agent" do
    ExternalCalendarEvent.create!(agent:, url: "1234", starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)

    described_class.new.perform(agent)

    expect(ExternalCalendarEvent.where(agent:)).to be_empty
    expect(agent.reload.caldav_config).to be_nil
  end

  context "quand le serveur répond 404 à la suppression d'un événement" do
    before do
      allow(caldav_events).to receive(:delete)
        .with("https://caldav.example.com/event.ics")
        .and_raise(Calendav::RequestError.new(instance_double(HTTP::Response, status: HTTP::Response::Status.new(404))))
    end

    it "ignore l'erreur" do
      expect { described_class.new.perform(agent) }.not_to raise_error
    end
  end
end
