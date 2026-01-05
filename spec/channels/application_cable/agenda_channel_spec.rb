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
end
