RSpec.describe User::ParticipationPolicy, type: :policy do
  subject { described_class }

  shared_examples "included in scope" do
    it "is included in scope" do
      expect(User::ParticipationPolicy::Scope.new(pundit_context, Participation).resolve).to include(participation)
    end
  end

  shared_examples "not included in scope" do
    it "is not included in scope" do
      expect(User::ParticipationPolicy::Scope.new(pundit_context, Participation).resolve).not_to include(participation)
    end
  end

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:user) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:pundit_context) { user }
  let!(:relative) do
    create(:user, :relative, responsible: user, first_name: "Petit", last_name: "Bébé")
  end
  let!(:rdv) { create(:rdv, :collectif, :without_users, organisation: organisation, agents: [agent]) }

  context "Participation belongs to user" do
    let!(:participation) { create(:participation, user: user, rdv: rdv) }

    it_behaves_like "permit actions", :participation, :create?, :cancel?
    it_behaves_like "included in scope"
  end

  context "Participation belongs to relative" do
    let!(:participation) { create(:participation, user: relative, rdv: rdv) }

    it_behaves_like "permit actions", :participation, :create?, :cancel?
    it_behaves_like "included in scope"
  end

  context "Participation belongs to relative for a individual RDV change" do
    let!(:rdv) { create(:rdv, users: [relative], organisation: organisation, agents: [agent]) }
    let(:participation) { rdv.participations.first }

    it_behaves_like "not permit actions", :participation, :cancel?
    it_behaves_like "permit actions", :participation, :create?
    it_behaves_like "included in scope"
  end

  context "Participation belongs to another user for a individual RDV change" do
    let!(:rdv) { create(:rdv, users: [user2], organisation: organisation, agents: [agent]) }
    let(:participation) { rdv.participations.first }

    it_behaves_like "not permit actions", :participation, :create?, :cancel?
    it_behaves_like "not included in scope"
  end

  context "Participation belongs to another user" do
    let!(:participation) { build(:participation, user: user2, rdv: rdv) }

    it_behaves_like "not permit actions", :participation, :create?, :cancel?
    it_behaves_like "not included in scope"
  end

  context "User is invited to participate" do
    let!(:participation) { create(:participation, user: user, rdv: rdv) }

    before { user.mark_as_signed_in_with_invitation_token! }

    it_behaves_like "permit actions", :participation, :create?, :cancel?
    it_behaves_like "included in scope"
  end

  context "Rdv is revoked" do
    let!(:rdv) { create(:rdv, :collectif, :without_users, organisation: organisation, agents: [agent], starts_at: Time.zone.yesterday) }
    let!(:participation) { create(:participation, user: user2, rdv: rdv) }

    before { participation.update(status: "revoked") }

    it_behaves_like "not permit actions", :participation, :create?, :cancel?
    it_behaves_like "not included in scope"
  end
end
