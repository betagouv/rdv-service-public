RSpec.describe Caldav::ExportRdvToCaldavJob do
  let(:agent) { create(:agent, :with_caldav_config) }
  let(:agents_rdv) { create(:agents_rdv, agent:) }
  let(:caldav_client) { instance_double(Calendav::Client, events: caldav_events) }
  let(:caldav_events) { instance_double(Calendav::Clients::EventsClient) }
  let(:ics_formatter) { instance_double(Icalendar::Calendar, to_ical: "BEGIN:VCALENDAR...") }

  before do
    allow_any_instance_of(Agent).to receive(:caldav_client).and_return(caldav_client) # rubocop:disable RSpec/AnyInstance
    allow(IcalFormatters::Ics).to receive(:from_payload).and_return(ics_formatter)
  end

  context "quand l'agent n'existe pas" do
    it "ne fait rien" do
      expect(caldav_events).not_to receive(:create)
      described_class.new.perform(agents_rdv.id, -1)
    end
  end

  context "quand l'agent n'a pas de config caldav" do
    let(:agent) { create(:agent) }

    it "ne fait rien" do
      expect(caldav_client).not_to receive(:events)
      described_class.new.perform(agents_rdv.id, agent.id)
    end
  end

  context "quand l'agents_rdv existe sans caldav_url (création)" do
    let(:created_event) { instance_double(Calendav::Event, url: "https://caldav.example.com/event.ics") }

    before { allow(caldav_events).to receive(:create).and_return(created_event) }

    it "crée l'événement sur le serveur caldav" do
      expect(caldav_events).to receive(:create).with(agent.caldav_agenda_url, "agents_rdv-#{agents_rdv.id}.ics", "BEGIN:VCALENDAR...")
      described_class.new.perform(agents_rdv.id, agent.id)
    end

    it "enregistre l'url de l'événement créé sur l'agents_rdv" do
      described_class.new.perform(agents_rdv.id, agent.id)
      expect(agents_rdv.reload.caldav_url).to eq("https://caldav.example.com/event.ics")
    end
  end

  context "quand l'agents_rdv existe avec une caldav_url (mise à jour)" do
    let(:agents_rdv) { create(:agents_rdv, agent:, caldav_url: "https://caldav.example.com/event.ics") }

    before { allow(caldav_events).to receive(:update) }

    it "met à jour l'événement sur le serveur caldav" do
      expect(caldav_events).to receive(:update).with("https://caldav.example.com/event.ics", "BEGIN:VCALENDAR...")
      described_class.new.perform(agents_rdv.id, agent.id)
    end
  end

  context "quand l'agents_rdv n'existe plus et qu'un caldav_event_url est fourni (suppression)" do
    let(:caldav_event_url) { "https://caldav.example.com/event.ics" }

    before { allow(caldav_events).to receive(:delete) }

    it "supprime l'événement sur le serveur caldav" do
      expect(caldav_events).to receive(:delete).with(caldav_event_url)
      described_class.new.perform(-1, agent.id, caldav_event_url:)
    end
  end

  context "quand l'agents_rdv n'existe plus et qu'aucun caldav_event_url n'est fourni" do
    it "ne fait rien" do
      expect(caldav_client).not_to receive(:events)
      described_class.new.perform(-1, agent.id)
    end
  end
end
