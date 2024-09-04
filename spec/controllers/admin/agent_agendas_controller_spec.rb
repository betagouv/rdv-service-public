RSpec.describe Admin::AgentAgendasController, type: :controller do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

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

  describe "#toggle_displays" do
    it "redirect to agenda" do
      put :toggle_displays, params: { id: agent.id, organisation_id: organisation.id, agent: { display_cancelled_rdv: true } }
      expect(response).to redirect_to(admin_organisation_agent_agenda_path)
    end

    context "about saturdays" do
      it "changes the display of saturdays for the current agent" do
        put :toggle_displays, params: { id: agent.id, organisation_id: organisation.id, agent: { display_saturdays: true } }
        expect(agent.reload.display_saturdays).to be(true)
      end

      context "when showing another agent's calendar" do
        # The option to display or hide saturdays applies to all the calendars that the agent sees, not just their own.
        # But it only applies to themselves, they can't change what another agent can do.
        it "changes the display for the current agent, not the other one" do
          other_agent = create(:agent, organisations: [organisation])
          put :toggle_displays, params: { id: other_agent.id, organisation_id: organisation.id, agent: { display_saturdays: true } }
          expect(agent.reload.display_saturdays).to be(true)
        end
      end
    end

    context "about cancelled RDV" do
      it "set the display of cancelled rdv for the current agent to false" do
        put :toggle_displays, params: { id: agent.id, organisation_id: organisation.id, agent: { display_cancelled_rdv: false } }
        expect(agent.reload.display_cancelled_rdv).to be(false)
      end

      it "set the display of cancelled rdv for the current agent to true" do
        put :toggle_displays, params: { id: agent.id, organisation_id: organisation.id, agent: { display_cancelled_rdv: true } }
        expect(agent.reload.display_cancelled_rdv).to be(true)
      end
    end
  end
end
