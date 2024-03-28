RSpec.describe Admin::RdvsCollectifsController, type: :controller do
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, :collectif, organisation: organisation) }
  let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

  before { sign_in agent }

  describe "POST create" do
    render_views

    subject(:create_request) { post :create, params: params }

    let(:lieu) { create(:lieu, organisation: organisation) }
    let(:starts_at) { 1.week.since }
    let(:params) do
      {
        organisation_id: organisation.id,
        rdv: {
          motif_id: motif.id,
          lieu_id: lieu.id,
          duration_in_min: 30,
          agent_ids: [agent.id],
          starts_at: starts_at,
        },
      }
    end

    before { stub_netsize_ok }

    it "creates the rdv and flashes success" do
      expect { create_request }.to change(Rdv, :count).by(1)
      expect(flash[:notice]).to match(/Le rendez-vous a été créé/)
    end

    context "when the rdv is in the past" do
      let(:starts_at) { 1.week.ago }

      it "shows a benign error" do
        expect { create_request }.not_to change(Rdv, :count)
        expect(response.body).to include("Ce rendez-vous a une date située dans le passé")
      end
    end

    context "when the rdv is created by an agent" do
      let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

      it "creates the rdv with the agent as created_by" do
        expect { create_request }.to change(Rdv, :count).by(1)
        expect(Rdv.last.created_by).to eq(agent)
      end
    end
  end
end
