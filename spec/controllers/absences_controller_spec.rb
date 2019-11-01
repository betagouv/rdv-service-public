RSpec.describe AbsencesController, type: :controller do
  render_views

  let(:agent) { create(:agent) }
  let(:organisation_id) { agent.organisation_ids.first }
  let!(:absence) { create(:absence, agent_id: agent.id, organisation_id: organisation_id) }

  before do
    sign_in agent
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { organisation_id: organisation_id }
      expect(response).to be_successful
    end

    describe "for json format" do
      let!(:absence1) { create(:absence, agent: agent, starts_at: Time.zone.parse("21/07/2019 08:00"), ends_at: Time.zone.parse("21/07/2019 10:00")) }
      let!(:absence2) { create(:absence, agent: agent, starts_at: Time.zone.parse("20/08/2019 08:00"), ends_at: Time.zone.parse("31/08/2019 22:00")) }

      before do
        sign_in agent
      end

      subject { get :index, params: { format: "json", organisation_id: organisation_id, start: start_time, end: end_time } }

      before do
        subject
        @parsed_response = JSON.parse(response.body)
      end

      context "when the absence is in window" do
        let(:start_time) { Time.zone.parse("20/07/2019 00:00") }
        let(:end_time) { Time.zone.parse("27/07/2019 00:00") }

        it { expect(response).to have_http_status(:ok) }

        it "should return absence1" do
          expect(@parsed_response.size).to eq(1)

          first = @parsed_response[0]
          expect(first.size).to eq(5)
          expect(first["title"]).to eq("Absence")
          expect(first["start"]).to eq(absence1.starts_at.as_json)
          expect(first["end"]).to eq(absence1.ends_at.as_json)
          expect(first["backgroundColor"]).to eq("#7f8c8d")
          expect(first["url"]).to eq(edit_absence_path(absence1))
        end
      end

      context "when the absence starts in window" do
        let(:start_time) { Time.zone.parse("19/08/2019 00:00") }
        let(:end_time) { Time.zone.parse("21/08/2019 00:00") }

        it { expect(response).to have_http_status(:ok) }

        it "should return absence2" do
          expect(@parsed_response.size).to eq(1)

          first = @parsed_response[0]
          expect(first.size).to eq(5)
          expect(first["title"]).to eq("Absence")
          expect(first["start"]).to eq(absence2.starts_at.as_json)
          expect(first["end"]).to eq(absence2.ends_at.as_json)
          expect(first["backgroundColor"]).to eq("#7f8c8d")
          expect(first["url"]).to eq(edit_absence_path(absence2))
        end
      end

      context "when the absence ends in window" do
        let(:start_time) { Time.zone.parse("31/08/2019 00:00") }
        let(:end_time) { Time.zone.parse("1/09/2019 00:00") }

        it { expect(response).to have_http_status(:ok) }

        it "should return absence2" do
          expect(@parsed_response.size).to eq(1)

          first = @parsed_response[0]
          expect(first.size).to eq(5)
          expect(first["title"]).to eq("Absence")
          expect(first["start"]).to eq(absence2.starts_at.as_json)
          expect(first["end"]).to eq(absence2.ends_at.as_json)
          expect(first["backgroundColor"]).to eq("#7f8c8d")
          expect(first["url"]).to eq(edit_absence_path(absence2))
        end
      end

      context "when the absence is around window" do
        let(:start_time) { Time.zone.parse("23/08/2019 00:00") }
        let(:end_time) { Time.zone.parse("27/08/2019 00:00") }

        it { expect(response).to have_http_status(:ok) }

        it "should return absence2" do
          expect(@parsed_response.size).to eq(1)

          first = @parsed_response[0]
          expect(first.size).to eq(5)
          expect(first["title"]).to eq("Absence")
          expect(first["start"]).to eq(absence2.starts_at.as_json)
          expect(first["end"]).to eq(absence2.ends_at.as_json)
          expect(first["backgroundColor"]).to eq("#7f8c8d")
          expect(first["url"]).to eq(edit_absence_path(absence2))
        end
      end
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { organisation_id: organisation_id }
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { id: absence.to_param }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      let(:valid_attributes) do
        build(:absence).attributes
      end

      it "creates a new Absence" do
        expect do
          post :create, params: { organisation_id: organisation_id, absence: valid_attributes }
        end.to change(Absence, :count).by(1)
      end

      it "redirects to the created absence" do
        post :create, params: { organisation_id: organisation_id, absence: valid_attributes }
        expect(response).to redirect_to(organisation_absences_path(organisation_id))
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) do
        {
          starts_at: "12/09/2019 16:00",
          ends_at: "12/09/2019 15:00",
        }
      end

      it "does not create a new Absence" do
        expect do
          post :create, params: { organisation_id: organisation_id, absence: invalid_attributes }
        end.not_to change(Absence, :count)
      end

      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { organisation_id: organisation_id, absence: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    subject { put :update, params: { id: absence.to_param, absence: new_attributes } }

    before { subject }

    context "with valid params" do
      let(:new_attributes) do
        {
          title: "Le nouveau nom",
        }
      end

      it "updates the requested absence" do
        absence.reload
        expect(absence.title).to eq("Le nouveau nom")
      end

      it "redirects to the absence" do
        expect(response).to redirect_to(organisation_absences_path(organisation_id))
      end
    end

    context "with invalid params" do
      let(:new_attributes) do
        {
          starts_at: "12/09/2019 16:00",
          ends_at: "12/09/2019 15:00",
        }
      end

      it "returns a success response (i.e. to display the 'edit' template)" do
        expect(response).to be_successful
      end

      it "does not change absence name" do
        absence.reload
        expect(absence.starts_at.to_s).not_to eq("2019-09-12 16:00:00 +0200")
        expect(absence.ends_at.to_s).not_to eq("2019-09-12 15:00:00 +0200")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested absence" do
      expect do
        delete :destroy, params: { id: absence.to_param }
      end.to change(Absence, :count).by(-1)
    end

    it "redirects to the absences list" do
      delete :destroy, params: { id: absence.to_param }
      expect(response).to redirect_to(organisation_absences_path(organisation_id))
    end
  end
end
