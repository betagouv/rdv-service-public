RSpec.describe SuperAdmin::AgentPolicy, type: :policy do
  subject { described_class }

  let!(:super_admin) { create(:super_admin) }
  let!(:pundit_context) { super_admin }
  let!(:agent) { create(:agent) }

  context "Permitted actions for super_admin" do
    it_behaves_like "permit actions", :agent, :sign_in_as?, :invite?, :index?, :show?, :create?, :new?, :edit?, :update?, :destroy?
  end

  context "permitted actions for support" do
    let!(:pundit_context) { create(:super_admin, :support) }

    it_behaves_like "permit actions", :agent, :sign_in_as?, :invite?, :index?, :show?, :create?, :new?, :edit?, :update?, :destroy?
  end
end
