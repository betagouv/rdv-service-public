describe SuperAdmin::AgentServicePolicy, type: :policy do
  subject { described_class }

  let!(:super_admin) { create(:super_admin) }
  let!(:pundit_context) { super_admin }
  let!(:agent) { create(:agent) }
  let!(:agent_service) { create(:agent_service, agent: agent) }

  context "Permitted actions for super_admin" do
    it_behaves_like "permit actions", :agent_service, :show?, :destroy?
    it_behaves_like "not permit actions", :agent_service, :index?, :new?, :create?, :edit?, :update?
  end

  context "permitted actions for support" do
    let!(:pundit_context) { create(:super_admin, :support) }

    it_behaves_like "permit actions", :agent_service, :show?, :destroy?
    it_behaves_like "not permit actions", :agent_service, :index?, :new?, :create?, :edit?, :update?
  end
end
