RSpec.describe Agent::UserPolicy, type: :policy do
  subject { described_class }

  it "création autorisée quand l'agent a accès à l'organisation de l'usager" do
    organisation = create(:organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    user = build(:user)
    user.user_profiles.build(organisation:) # comme dans Admin::UsersController#prepare_create
    expect(described_class.new(agent, user).create?).to be(true)
  end

  it "création refusée quand l'agent n'a pas accès à l'organisation de l'usager" do
    organisation = create(:organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    user = build(:user)
    user.user_profiles.build(organisation: create(:organisation))
    expect(described_class.new(agent, user).create?).to be(false)
  end

  it "création refusée quand l'agent n'a accès qu’à certaines organisations de l'usager" do
    organisation = create(:organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    user = build(:user)
    user.user_profiles.build(organisation:)
    user.user_profiles.build(organisation: create(:organisation))
    expect(described_class.new(agent, user).create?).to be(false)
  end

  it "création refusée quand l'usager n'a pas de user_profiles" do
    organisation = create(:organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    user = build(:user)
    expect(described_class.new(agent, user).create?).to be(false)
  end

  it "création autorisée quand l'agent a accès à l'organisation de l'usager créée via l'API" do
    organisation = create(:organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    user = User.new
    user.assign_attributes(organisation_ids: [organisation.id]) # comme dans Api::V1::UsersController#create
    expect(described_class.new(agent, user).create?).to be(true)
  end

  it "création refusée quand l'agent n'a pas accès à l'organisation de l'usager créée via l'API" do
    organisation = create(:organisation)
    agent = create(:agent, basic_role_in_organisations: [organisation])
    user = User.new
    user.assign_attributes(organisation_ids: [create(:organisation).id]) # comme dans Api::V1::UsersController#create
    expect(described_class.new(agent, user).create?).to be(false)
  end

  describe "scope" do
    it "returns empty without users" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      policy = described_class::Scope.new(AgentOrganisationContext.new(agent, organisation), User)
      expect(policy.resolve).to be_empty
    end

    it "user of organisation" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      user = create(:user, organisations: [organisation])
      create(:user, organisations: [create(:organisation)])
      policy = described_class::Scope.new(AgentOrganisationContext.new(agent, organisation), User)
      expect(policy.resolve).to eq([user])
    end
  end
end
