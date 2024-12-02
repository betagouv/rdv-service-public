RSpec.describe User::RdvPolicy, type: :policy do
  subject { described_class }

  shared_examples "included in scope" do
    it "is included in scope" do
      expect(User::RdvPolicy::Scope.new(pundit_context, Rdv).resolve).to include(rdv)
    end
  end

  shared_examples "not included in scope" do
    it "is not included in scope" do
      expect(User::RdvPolicy::Scope.new(pundit_context, Rdv).resolve).not_to include(rdv)
    end
  end

  let(:organisation) { create(:organisation) }
  let(:service) { create(:service) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let(:motif) { create(:motif, organisation: organisation, service: service) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:pundit_context) { user }
  let(:relative) do
    create(:user, :relative, responsible: user, first_name: "Petit", last_name: "Bébé")
  end
  let!(:rdv) { create(:rdv, organisation: organisation, agents: [agent], motif: motif, users: [user], created_by: user) }

  context "Rdv belongs to user" do
    it_behaves_like "permit actions", :rdv, :show?, :index?, :new?, :edit?, :update?, :create?, :creneaux?, :cancel?
    it_behaves_like "included in scope"
  end

  context "Rdv belongs to user for a relative" do
    let(:rdv) { create(:rdv, organisation: organisation, agents: [agent], motif: motif, users: [relative], created_by: user) }

    it_behaves_like "permit actions", :rdv, :show?, :index?, :new?, :edit?, :update?, :create?, :creneaux?, :cancel?
    it_behaves_like "included in scope"
  end

  context "Rdv belongs to another user" do
    let(:rdv) { create(:rdv, organisation: organisation, agents: [agent], motif: motif, users: [user2], created_by: user) }

    it_behaves_like "permit actions", :rdv, :index?
    it_behaves_like "not permit actions", :rdv, :show?, :new?, :edit?, :update?, :create?, :creneaux?, :cancel?
    it_behaves_like "not included in scope"
  end

  context "Rdv belongs to user but motif is not visible" do
    let(:motif) { create(:motif, organisation: organisation, service: service, visibility_type: Motif::INVISIBLE) }

    it_behaves_like "not included in scope"
    it_behaves_like "not permit actions", :rdv, :show?, :edit?, :update?, :cancel?, :creneaux?, :can_change_participants?
  end

  context "User signed in with an invitation token" do
    before { user.signed_in_with_invitation_token! }

    it_behaves_like "permit actions", :rdv, :new?, :create?
    it_behaves_like "not permit actions", :rdv, :index?, :edit?, :update?, :creneaux?, :cancel?, :show?
    it_behaves_like "included in scope"
  end

  context "Rdv is collective" do
    context "Rdv belongs to user" do
      let!(:rdv) { create(:rdv, :collectif, organisation: organisation, agents: [agent], users: [user]) }

      it_behaves_like "permit actions", :rdv, :show?, :index?, :new?
      it_behaves_like "not permit actions", :rdv, :edit?, :update?, :creneaux?, :create?, :cancel?
      it_behaves_like "included in scope"
    end

    context "Rdv belongs to user for a relative" do
      let(:rdv) { create(:rdv, :collectif, organisation: organisation, agents: [agent], users: [relative]) }

      it_behaves_like "permit actions", :rdv, :show?, :index?, :new?
      it_behaves_like "not permit actions", :rdv, :edit?, :update?, :creneaux?, :create?, :cancel?
      it_behaves_like "included in scope"
    end

    context "Rdv belongs to another user" do
      let(:rdv) { create(:rdv, :collectif, organisation: organisation, agents: [agent], users: [user2]) }

      it_behaves_like "permit actions", :rdv, :index?, :new?
      it_behaves_like "not permit actions", :rdv, :show?, :edit?, :update?, :creneaux?, :create?, :cancel?
      it_behaves_like "included in scope"
    end

    context "User is invited, rdv has no users" do
      let(:rdv) { create(:rdv, :collectif, :without_users, organisation: organisation, agents: [agent]) }

      before { user.signed_in_with_invitation_token! }

      it_behaves_like "permit actions", :rdv, :new?
      it_behaves_like "not permit actions", :rdv, :index?, :edit?, :update?, :creneaux?, :cancel?, :show?, :create?
      it_behaves_like "included in scope"
    end
  end
end
