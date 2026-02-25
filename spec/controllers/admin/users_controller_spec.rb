RSpec.describe Admin::UsersController, type: :controller do
  render_views

  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory:) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  before do
    sign_in agent
  end

  describe "GET search" do
    it "returns users as JSON" do
      travel_to(Time.zone.parse("2024-10-23 16:00"))
      francis = create(:user, first_name: "Francis", last_name: "Factice", birth_date: Date.new(1990, 4, 2), organisations: [organisation])
      get :search, params: { term: "fra", organisation_id: organisation.id, format: :json }
      expect(response.parsed_body).to eq({ "results" => [{ "id" => francis.id, "text" => "FACTICE Francis - 2/04/1990 - 34 ans" }] })
    end
  end

  describe "DELETE destroy" do
    let!(:user) { create(:user, organisations: [organisation]) }

    it "removes user from organisation" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: user.id }
        user.reload
      end.to change(user, :organisation_ids).from([organisation.id]).to([])
    end

    it "appears to destroy user" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: user.id }
      end.to change(User, :count)
    end

    it "not really destroy user" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: user.id }
      end.not_to change { User.unscoped.count }
    end
  end

  describe "GET new" do
    it "n’affiche pas le champ d’adresse par défaut" do
      get :new, params: { organisation_id: organisation.id }
      expect(response).to be_successful
      expect(response.body).not_to include("Adresse")
    end

    context "l’espace a le champ d’adresse activé" do
      let(:territory) { create(:territory, enable_address_field: true) }

      it "affiche le champ d’adresse" do
        get :new, params: { organisation_id: organisation.id }
        expect(response).to be_successful
        expect(response.body).to include("Adresse")
      end
    end
  end

  describe "POST #create" do
    subject { post :create, params: { organisation_id: organisation.id, user: attributes } }

    context "for user without email" do
      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
          user_profiles_attributes: { "0" => { "organisation_id" => organisation.id.to_s } },
        }
      end

      it { expect { subject }.to change(User, :count).by(1) }

      it "does not send an invite" do
        post :create, params: { organisation_id: organisation.id, user: attributes, invite_on_create: 0 }
        expect(assigns(:user).invitation_sent_at).to be_nil
      end

      it "redirects to the created user" do
        subject
        expect(response).to redirect_to(admin_organisation_user_path(organisation.id, User.last.id))
      end
    end

    context "for user with already existing email" do
      let!(:user) { create(:user) }

      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
          email: user.email,
          user_profiles_attributes: { "0" => { "organisation_id" => organisation.id.to_s } },
        }
      end

      it { expect { subject }.not_to change(User, :count) }
      it { expect(subject).to render_template(:new) }
    end

    context "with invalid params" do
      let(:attributes) do
        {
          first_name: "Michel",
          user_profiles_attributes: { "0" => { "organisation_id" => organisation.id.to_s } },
        }
      end
      let(:format) { :html }

      it { expect { subject }.not_to change(User, :count) }
      it { expect(subject).to render_template(:new) }

      it do
        subject
        expect(assigns(:user_to_compare)).to be_nil
      end

      it "does not send an invite" do
        subject
        expect(assigns(:user).invitation_sent_at).to be_nil
      end

      context "with valid email" do
        let(:attributes) do
          {
            first_name: "Michel",
            last_name: "Lapin",
            email: "michel@lapin.com",
            user_profiles_attributes: { "0" => { "organisation_id" => organisation.id.to_s } },
          }
        end
        let(:format) { format }

        it "sends an invitation code" do
          expect { post :create, params: { organisation_id: organisation.id, user: attributes, invite_on_create: "1" } }
            .to have_enqueued_mail(Users::LoginCodeMailer, :invitation_code)
        end
      end
    end
  end

  describe "#index" do
    it "return success" do
      get :index, params: { organisation_id: organisation.id }
      expect(response).to be_successful
    end

    it "assigns users" do
      get :index, params: { organisation_id: organisation.id }
      expect(assigns(:users)).to eq([])
    end

    it "return success with with_me_as_referent filter" do
      get :index, params: { organisation_id: organisation.id, with_me_as_referent: 1 }
      expect(response).to be_successful
    end

    it "assigns user where I am referent" do
      user_with_referent = create(:user, referent_agents: [agent], organisations: [organisation])
      create(:user, referent_agents: [], organisations: [organisation])
      get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
      expect(assigns(:users)).to eq([user_with_referent])
    end
  end

  describe "GET #show" do
    subject { get :show }

    context "l’usager existe" do
      let!(:user) { create(:user, first_name: "Lola", organisations: [organisation]) }

      it "montre l’usager" do
        get :show, params: { organisation_id: organisation.id, id: user.id }
        expect(response).to be_successful
        expect(response.body).to include("Lola")
      end

      it "n'affiche pas l’adresse de l’usager par défaut" do
        get :show, params: { organisation_id: organisation.id, id: user.id }
        expect(response).to be_successful
        expect(response.body).not_to include("Adresse")
      end

      context "l’espace a le champ d’adresse activé" do
        let(:territory) { create(:territory, enable_address_field: true) }

        it "montre l’adresse de l’usager" do
          user.update(address: "10 rue des Lilas")
          get :show, params: { organisation_id: organisation.id, id: user.id }
          expect(response).to be_successful
          expect(response.body).to include("10 rue des Lilas")
        end
      end
    end

    context "l’usager a été soft-deleted" do
      let!(:user) { create(:user, organisations: [organisation]) }

      before { user.soft_delete! }

      it "redirige avec un message d’erreur" do
        get :show, params: { organisation_id: organisation.id, id: user.id }
        expect(response).to redirect_to(admin_organisation_users_path(organisation.id))
        expect(flash[:error]).to match(/a été supprimé/)
      end
    end
  end

  describe "GET #link_to_organisation" do
    let!(:user_from_other_territory) { create(:user, organisations: [create(:organisation)]) }

    context "without a secure key" do
      it "redirects with an error message" do
        expect do
          get :link_to_organisation, params: { organisation_id: organisation.id, id: user_from_other_territory.id }
        end.not_to change { user_from_other_territory.reload.organisation_ids }

        expect(response).to redirect_to(authenticated_agent_root_url)
        expect(flash[:error]).to match(/Vous n’avez pas les droits suffisants/)
      end
    end

    context "with a secure key" do
      let(:secure_key) { SecureRandom.uuid }

      before do
        Redis.with_connection do |redis|
          redis_key = "link_to_organisation:secure_key:#{secure_key}"
          redis.set(redis_key, user_from_other_territory.id.to_s, ex: 30.seconds)
        end
      end

      it "redirects with an error message" do
        expect do
          get :link_to_organisation, params: { organisation_id: organisation.id, id: user_from_other_territory.id, secure_key: }
        end.to change { user_from_other_territory.organisations.count }.by(1)

        expect(response).to redirect_to("/admin/organisations/#{organisation.id}/users/#{user_from_other_territory.id}")
      end
    end
  end
end
