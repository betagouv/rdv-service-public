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

  describe "#toggle_display_saturdays" do
    subject do
      put :toggle_display_saturdays, params: { id: agent.id, organisation_id: organisation.id, agent: { display_saturdays: true } }
    end

    it "changes the display of saturdays for the current agent" do
      expect { subject }.to change { agent.reload.display_saturdays }.to true
      expect(response).to redirect_to(admin_organisation_agent_agenda_path)
    end

    context "when showing another agent's calendar" do
      subject do
        put :toggle_display_saturdays, params: { id: other_agent.id, organisation_id: organisation.id, agent: { display_saturdays: true } }
      end

      let(:other_agent) { create(:agent, organisations: [organisation]) }

      # The option to display or hide saturdays applies to all the calendars that the agent sees, not just their own.
      # But it only applies to themselves, they can't change what another agent can do.
      it "changes the display for the current agent, not the other one" do
        expect { subject }.to change { agent.reload.display_saturdays }.to true
      end
    end
  end
end
