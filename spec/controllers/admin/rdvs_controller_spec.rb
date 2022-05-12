# frozen_string_literal: true

describe Admin::RdvsController, type: :controller do
  let(:now) { Time.zone.parse("19/07/2019 15:00") }
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user, first_name: "Marie", last_name: "Denis") }
  let!(:motif) { create(:motif, name: "Suivi", organisation: organisation, service: service, color: "#1010FF") }

  before do
    travel_to(now)
    sign_in agent
  end

  describe "GET index" do
    let(:lieu) { create(:lieu, organisation: organisation, name: "MDS Orgeval") }

    it "respond success" do
      get(:index, params: { organisation_id: organisation.id, agent_id: agent.id, start: Time.zone.parse("20/07/2019 08:00"), end: Time.zone.parse("27/07/2019 09:00") })

      expect(response).to be_successful
    end

    it "assign RDVS" do
      rdv = create(:rdv, organisation: organisation, motif: motif)
      get(:index, params: { organisation_id: organisation.id })

      expect(assigns(:rdvs)).to eq([rdv])
    end

    it "assign form" do
      get(:index, params: { organisation_id: organisation.id, agent_id: agent.id, start: Time.zone.parse("20/07/2019 08:00"), end: Time.zone.parse("27/07/2019 09:00") })

      expect(assigns(:form)).not_to be_nil
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      rdv = create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation)
      get :edit, params: { organisation_id: organisation.id, id: rdv.to_param }
      expect(response).to be_successful
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "redirects to the rdv" do
        now = Time.zone.parse("2020-11-23 14h00")
        travel_to(now)
        rdv = create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation)
        lieu = create(:lieu, organisation: organisation)
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: { lieu_id: lieu.id } }
        expect(response).to redirect_to(admin_organisation_rdv_path(organisation, rdv))
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        rdv = create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation)
        new_attributes = { duration_in_min: -10 }
        put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: new_attributes }
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end

      it "does not change rdv" do
        rdv = create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation)
        new_attributes = { duration_in_min: -10 }
        expect do
          put :update, params: { organisation_id: organisation.id, id: rdv.to_param, rdv: new_attributes }
        end.not_to change(rdv, :duration_in_min)
      end
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      now = Time.zone.parse("2020-11-23 14h00")
      travel_to(now)
      rdv = create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation)
      get :show, params: { organisation_id: organisation.id, id: rdv.id }
      expect(response).to be_successful
    end
  end

  describe "DELETE destroy" do
    context "regular agent" do
      it "does not destroy rdv" do
        rdv = create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation)

        delete :destroy, params: { organisation_id: organisation.id, id: rdv.id }
        expect(response).not_to be_successful
      end
    end

    context "admin agent" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }

      it "destroy rdv" do
        rdv = create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation)

        expect do
          delete :destroy, params: { organisation_id: organisation.id, id: rdv.id }
        end.to change(Rdv, :count).by(-1)
      end
    end

    context "existing receipts" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service) }

      it "does not destroy rdv" do
        rdv = create(:rdv, motif: motif, agents: [agent], users: [user], organisation: organisation)
        create(:receipt, rdv: rdv)

        delete :destroy, params: { organisation_id: organisation.id, id: rdv.id }
        expect(response).not_to be_successful
      end
    end
  end

  describe "#export" do
    it "redirect to index" do
      post :export, params: { organisation_id: organisation.id }
      expect(response).to redirect_to(admin_organisation_rdvs_path)
    end

    it "call Agents::ExportMailer" do
      params = {
        start: nil,
        end: nil,
        organisation_id: organisation.id.to_s,
        agent_id: "",
        user_id: "",
        lieu_id: "",
        status: "",
      }

      # rubocop:disable RSpec/StubbedMock
      expect(Agents::ExportMailer).to receive(:rdv_export).with(
        agent,
        organisation,
        "start" => params[:start],
        "end" => params[:end],
        "organisation_id" => organisation.id.to_s,
        "agent_id" => params[:agent_id],
        "user_id" => params[:user_id],
        "lieu_id" => params[:lieu_id],
        "status" => params[:status]
      ).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      # rubocop:enable RSpec/StubbedMock

      post :export, params: { organisation_id: organisation.id }.merge(params)
    end
  end
end
