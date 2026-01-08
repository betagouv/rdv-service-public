RSpec.describe AgendaChannel do
  let!(:current_agent) { create(:agent) }

  before do
    # initialize connection with identifiers
    stub_connection current_agent:
  end

  it "subscribes when passing the ID of an agent within scope" do
    colleague = create(:agent, organisations: [create(:organisation, agents: [current_agent])])
    subscribe(agent_id: colleague.id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("agenda:#{colleague.id}")
  end

  it "rejects subscription when passing the ID of an agent outside scope" do
    not_a_colleague = create(:agent, organisations: [create(:organisation)])
    subscribe(agent_id: not_a_colleague.id)
    expect(subscription).to be_rejected
  end

  it "rejects subscription when passing no agent_id" do
    subscribe
    expect(subscription).to be_rejected
  end

  it "rejects subscription and warns Sentry on unexpected error" do
    allow(Agent::AgentPolicy::Scope).to receive(:new).and_raise("woops")
    subscribe
    expect(subscription).to be_rejected
    expect(sentry_events.last.exception.values.first.value).to eq("woops (RuntimeError)")
  end

  describe "broadcasts" do
    it "fires on Rdv creation, update and deletion" do
      rdv_agent = create(:agent)
      rdv = nil
      expect do
        rdv = create(:rdv, agents: [rdv_agent])
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class)

      expect do
        rdv.update!(starts_at: 4.days.from_now)
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class)

      expect do
        rdv.destroy!
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class)
    end

    it "fires when adding, updating or removing a participation" do
      rdv_agent = create(:agent)
      rdv = create(:rdv, agents: [rdv_agent])

      expect do
        create(:participation, rdv:)
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class)

      expect do
        rdv.participations.last.update!(status: "seen")
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class)

      expect do
        rdv.participations.last.destroy!
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class)
    end

    it "fires when adding, updating or removing an AgentsRdv" do
      org = create(:organisation)
      rdv_agent = create(:agent, organisations: [org])
      colleague = create(:agent, organisations: [org])
      rdv = create(:rdv, agents: [rdv_agent])

      expect do
        create(:agents_rdv, rdv:, agent: colleague)
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class).and(
        have_broadcasted_to(colleague.id).from_channel(described_class)
      )

      expect do
        rdv.agents_rdvs.last.update!(agent_id: current_agent.id)
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class).and(
        have_broadcasted_to(colleague.id).from_channel(described_class)
      )

      expect do
        rdv.agents_rdvs.last.destroy!
      end.to have_broadcasted_to(rdv_agent.id).from_channel(described_class)
    end
  end
end
