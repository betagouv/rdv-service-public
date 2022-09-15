# frozen_string_literal: true

describe Admin::RdvsCollectifsController, type: :controller do
  let(:motif) { create(:motif, :collectif) }
  let(:organisation) { motif.organisation }
  let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

  before { sign_in agent }

  describe "POST create" do
    subject(:create_request) { post :create, params: params }

    let(:lieu) { create(:lieu, organisation: organisation) }
    let(:params) do
      {
        organisation_id: organisation.id,
        rdv: {
          motif_id: motif.id,
          lieu_id: lieu.id,
          duration_in_min: 30,
          agent_ids: [agent.id],
          starts_at: DateTime.new(2020, 4, 20, 8, 0, 0),
        },
      }
    end

    before { stub_netsize_ok }

    it "creates the rdv and flashes success" do
      expect { create_request }.to change(Rdv, :count).by(1)
      expect(flash[:notice]).to match(/créé/)
    end
  end
end
