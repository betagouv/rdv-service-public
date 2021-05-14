# frozen_string_literal: true

describe Admin::AgentAgendasController, type: :controller do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, organisations: [organisation]) }

  before { sign_in agent }

  describe "#show" do
    before do
      get :show, params: { id: agent.id, organisation_id: organisation.id }
    end

    it { expect(response).to be_successful }
    it { expect(assigns(:organisation)).to eq(organisation) }
    it { expect(assigns(:agent)).to eq(agent) }
    it { expect(assigns(:status)).to be_nil }
    it { expect(assigns(:selected_event_id)).to be_nil }
    it { expect(assigns(:date)).to be_nil }
  end
end
