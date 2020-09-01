describe Admin::UserNotesController, type: :controller do
  render_views

  describe "#create" do
    it "from user page, create a note and redirect to user page" do
      agent = create(:agent)
      organisation = agent.organisations.first
      user = create(:user, organisations: [organisation])
      sign_in agent
      expect  do
        post :create, params: { organisation_id: organisation.id, user_id: user.id, "user_note" => { "text" => "un truc nouveau à ajouter" } }
      end.to change(UserNote, :count).by(1)
      expect(response).to redirect_to(organisation_user_path(organisation, user, anchor: "notes"))
    end

    it "from rdv page, create a note for each users of rdv, and redirect to rdv page" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation])
      enfant = create(:user, :relative, responsible: user)
      rdv = create(:rdv, :future, users: [user, enfant], organisation: organisation)
      agent = rdv.agents.first
      sign_in agent

      request.headers["Referer"] = admin_organisation_rdv_path(organisation, rdv)
      expect do
        post :create, params: { organisation_id: organisation.id, user_id: user.id, "user_note" => { "user_ids" => enfant.id.to_s, "text" => "un truc nouveau à ajouter" } }
      end.to change(UserNote, :count).by(1)
      expect(response).to redirect_to(admin_organisation_rdv_path(organisation, rdv))
    end
  end

  describe "#index" do
    it "list user notes for current organisation" do
      organisation = create(:organisation)
      agent = create(:agent, organisations: [organisation])
      user = create(:user, organisations: [organisation])
      note = create(:user_note, organisation: organisation, user: user, agent: agent)
      sign_in agent

      get :index, params: { organisation_id: organisation.id, user_id: user.id }

      expect(response).to be_successful
      expect(assigns(:user)).to eq(user)
      expect(assigns(:notes)).to eq([note])
    end
  end

  describe "#destroy" do
    it "remove note from rdv page" do
      organisation = create(:organisation)
      agent = create(:agent, organisations: [organisation])
      user = create(:user, organisations: [organisation])
      note = create(:user_note, organisation: organisation, user: user, agent: agent)
      rdv = create(:rdv, :future, users: [user], organisation: organisation)

      sign_in agent

      request.headers["Referer"] = admin_organisation_rdv_path(organisation, rdv)
      expect do
        post :destroy, params: { organisation_id: organisation.id, user_id: user.id, id: note.id }
      end.to change(UserNote, :count).by(-1)

      expect(response).to redirect_to(admin_organisation_rdv_path(organisation, rdv))
    end
  end
end
