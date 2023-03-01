# frozen_string_literal: true

RSpec.describe Outlook::Synchronizable, type: :concern do
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
  let(:fake_agent) { create(:agent) }
  let(:agent) { create(:agent, microsoft_graph_token: "token") }
  let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
  let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }

  let(:expected_headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer token",
      "Content-Type" => "application/json",
      "Expect" => "",
      "Return-Client-Request-Id" => "true",
      "User-Agent" => "RDVSolidarites",
    }
  end

  let(:expected_description) do
    <<~HTML
      Participants:
      <ul><li>First LAST</li></ul>
      <br />

      Plus d'infos sur <href a="http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}">RDV Solidarités</href>:
      <br />

      Attention: ne modifiez pas cet évènement directement dans Outlook, car il ne sera pas mis à jour sur RDV Solidarités.
      Pour modifier ce rendez-vous, allez sur <href a="http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}/edit">RDV Solidarités</href>
    HTML
  end

  # I made the choice to have end_to_end tests in this file to make it easier to check the callback
  # behavior without dealing with the view and to encapsulate the test of the logic in a single file.
  describe "Create callback" do
    context "agent synced with outlook" do
      let(:expected_body) do
        {
          subject: "Super Motif",
          body: {
            contentType: "HTML",
            content: expected_description,
          },
          start: {
            dateTime: "2023-01-01T11:00:00+01:00",
            timeZone: "Europe/Paris",
          },
          end: {
            dateTime: "2023-01-01T11:30:00+01:00",
            timeZone: "Europe/Paris",
          },
          location: {
            displayName: "Par téléphone",
          },
          attendees: [],
        }
      end

      before do
        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
          .with(body: expected_body, headers: expected_headers)
          .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})
      end

      it "creates the Event in Outlook" do
        agents_rdv = create(:agents_rdv, agent: agent, rdv: rdv)

        expect(a_request(:post,
                         "https://graph.microsoft.com/v1.0/me/Events").with(body: expected_body)).to have_been_made.once
        expect(agents_rdv.reload.outlook_id).to eq("event_id")
      end
    end

    context "agent not synced with outlook" do
      let(:agent) { create(:agent) }

      it "does not call the Outlook API" do
        agents_rdv = create(:agents_rdv, agent: agent)

        expect(a_request(:post, "https://graph.microsoft.com/v1.0/me/Events")).not_to have_been_made
        expect(agents_rdv.reload.outlook_id).to be_nil
      end
    end

    context "agents_rdv already exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }

      it "does not call the Outlook API" do
        create(:agents_rdv, agent: agent, outlook_id: "abc")

        expect(a_request(:post, "https://graph.microsoft.com/v1.0/me/Events")).not_to have_been_made
      end
    end
  end

  describe "Update callback" do
    context "exists in outlook and agent is synced" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
      let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
      let!(:agents_rdv) { create(:agents_rdv, rdv: rdv, agent: agent, outlook_id: "abc") }

      let(:expected_body) do
        {
          subject: "Super Motif",
          body: {
            contentType: "HTML",
            content: expected_description,
          },
          start: {
            dateTime: "2023-01-01T11:00:00+01:00",
            timeZone: "Europe/Paris",
          },
          end: {
            dateTime: "2023-01-01T11:40:00+01:00",
            timeZone: "Europe/Paris",
          },
          location: {
            displayName: "Par téléphone",
          },
          attendees: [],
        }
      end

      before do
        stub_request(:patch, "https://graph.microsoft.com/v1.0/me/Events/abc")
          .with(body: expected_body, headers: expected_headers)
          .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})
      end

      stub_sentry_events

      it "updates the Outlook Event" do
        rdv.update(duration_in_min: 40)

        expect(a_request(:patch,
                         "https://graph.microsoft.com/v1.0/me/Events/abc").with(body: expected_body)).to have_been_made.once
        expect(sentry_events).to be_empty
      end
    end

    context "exists in outlook and agent is not synced" do
      let(:agent) { create(:agent) }
      let(:rdv) { create(:rdv) }
      let!(:agents_rdv) { create(:agents_rdv, agent: agent, rdv: rdv, outlook_id: "abc") }

      it "does not update the Outlook Event" do
        rdv.update(duration_in_min: 40)

        expect(a_request(:patch, "https://graph.microsoft.com/v1.0/me/Events/abc")).not_to have_been_made
      end
    end

    context "does not exists in outlook" do
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
      let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }

      let(:expected_body) do
        {
          subject: "Super Motif",
          body: {
            contentType: "HTML",
            content: expected_description,
          },
          start: {
            dateTime: "2023-01-01T11:00:00+01:00",
            timeZone: "Europe/Paris",
          },
          end: {
            dateTime: "2023-01-01T11:30:00+01:00",
            timeZone: "Europe/Paris",
          },
          location: {
            displayName: "Par téléphone",
          },
          attendees: [],
        }
      end
      let(:expected_updated_body) do
        {
          subject: "Super Motif",
          body: {
            contentType: "HTML",
            content: "plus d'infos dans RDV Solidarités: http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}",
          },
          start: {
            dateTime: "2023-01-01T11:00:00+01:00",
            timeZone: "Europe/Paris",
          },
          end: {
            dateTime: "2023-01-01T11:40:00+01:00",
            timeZone: "Europe/Paris",
          },
          location: {
            displayName: "Par téléphone",
          },
          attendees: [],
        }
      end

      before do
        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
          .with(body: expected_body, headers: expected_headers)
          .to_return(status: 200, body: { id: "" }.to_json, headers: {})
        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
          .with(body: expected_updated_body, headers: expected_headers)
          .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})
      end

      it "creates the Outlook Event" do
        agents_rdv = create(:agents_rdv, agent: agent, rdv: rdv)
        rdv.update(duration_in_min: 40)

        expect(a_request(:post,
                         "https://graph.microsoft.com/v1.0/me/Events").with(body: expected_updated_body)).to have_been_made.once
        expect(agents_rdv.reload.outlook_id).to eq("event_id")
      end
    end

    context "is cancelled and exists in outlook" do
      let(:organisation) { create(:organisation) }
      let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
      # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
      let(:fake_agent) { create(:agent) }
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:rdv) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
      let!(:agents_rdv) { create(:agents_rdv, rdv: rdv, agent: agent, outlook_id: "abc") }

      before do
        stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc").to_return(status: 204, body: "", headers: {})
      end

      it "destroys the Outlook Even" do
        rdv.update(cancelled_at: Time.zone.now, status: "revoked")

        expect(a_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")).to have_been_made.once
        expect(agents_rdv.reload.outlook_id).to be_nil
      end
    end

    context "is cancelled and does not exist in outlook" do
      let(:organisation) { create(:organisation) }
      let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
      # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
      let(:fake_agent) { create(:agent) }
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
      let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }

      let(:expected_body) do
        {
          subject: "Super Motif",
          body: {
            contentType: "HTML",
            content: expected_description,
          },
          start: {
            dateTime: "2023-01-01T11:00:00+01:00",
            timeZone: "Europe/Paris",
          },
          end: {
            dateTime: "2023-01-01T11:30:00+01:00",
            timeZone: "Europe/Paris",
          },
          location: {
            displayName: "Par téléphone",
          },
          attendees: [],
        }
      end

      before do
        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
          .with(body: expected_body, headers: expected_headers)
          .to_return(status: 200, body: { id: "" }.to_json, headers: {})
      end

      it "does not call Outlook::DestroyEventJob" do
        agents_rdv = create(:agents_rdv, agent: agent, rdv: rdv)
        expect do
          rdv.update(cancelled_at: Time.zone.now, status: "revoked")
        end.not_to have_enqueued_job(Outlook::DestroyEventJob).with(agents_rdv.outlook_id, agent.id)
      end
    end

    context "is soft_deleted and exists in outlook" do
      let(:organisation) { create(:organisation) }
      let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
      # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
      let(:fake_agent) { create(:agent) }
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:rdv) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
      let!(:agents_rdv) { create(:agents_rdv, rdv: rdv, agent: agent, outlook_id: "abc") }

      before do
        stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc").to_return(status: 204, body: "", headers: {})
      end

      it "destroys the Outlook Event" do
        rdv.update(deleted_at: Time.zone.now)

        expect(a_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")).to have_been_made.once
        # Important: we cannot delete the outlook_id as the agents_rdv is not longer correct (rdv required but deleted)
        expect(agents_rdv.reload.outlook_id).to eq("abc")
      end
    end
  end

  describe "Destroy callback" do
    context "agent synced with outlook and exists in outlook" do
      let(:organisation) { create(:organisation) }
      let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
      # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
      let(:fake_agent) { create(:agent) }
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:rdv) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
      let!(:agents_rdv) { create(:agents_rdv, rdv: rdv, agent: agent, outlook_id: "abc") }

      before do
        stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc").to_return(status: 204, body: "", headers: {})
      end

      it "destroys the Outlook Event" do
        rdv.destroy

        expect(a_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/abc")).to have_been_made.once
        expect { agents_rdv.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "agent not synced with outlook" do
      let(:organisation) { create(:organisation) }
      let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
      # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
      let(:fake_agent) { create(:agent) }
      let(:agent) { create(:agent) }
      let(:rdv) { create(:rdv, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
      let!(:agents_rdv) { create(:agents_rdv, rdv: rdv, agent: agent) }

      before do
        allow(Outlook::DestroyEventJob).to receive(:perform_later)

        rdv.destroy
      end

      it "does not call Outlook::DestroyEventJob" do
        expect do
          rdv.destroy
        end.not_to have_enqueued_job(Outlook::DestroyEventJob)
      end
    end

    context "agents_rdv does not exist in outlook" do
      let(:organisation) { create(:organisation) }
      let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
      # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
      let(:fake_agent) { create(:agent) }
      let(:agent) { create(:agent, microsoft_graph_token: "token") }
      let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
      let(:rdv) { create(:rdv, users: [user], motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }

      let(:expected_body) do
        {
          subject: "Super Motif",
          body: {
            contentType: "HTML",
            content: expected_description,
          },
          start: {
            dateTime: "2023-01-01T11:00:00+01:00",
            timeZone: "Europe/Paris",
          },
          end: {
            dateTime: "2023-01-01T11:30:00+01:00",
            timeZone: "Europe/Paris",
          },
          location: {
            displayName: "Par téléphone",
          },
          attendees: [],
        }
      end

      before do
        stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
          .with(body: expected_body, headers: expected_headers)
          .to_return(status: 200, body: { id: "" }.to_json, headers: {})

        allow(Outlook::DestroyEventJob).to receive(:perform_later)
      end

      it "does not call Outlook::DestroyEventJob" do
        create(:agents_rdv, agent: agent, rdv: rdv)
        expect do
          rdv.destroy
        end.not_to have_enqueued_job(Outlook::DestroyEventJob)
      end
    end
  end
end
