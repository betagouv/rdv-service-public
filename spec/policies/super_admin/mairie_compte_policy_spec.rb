describe SuperAdmin::MairieComptePolicy, type: :policy do
  subject { described_class }

  let!(:super_admin) { create(:super_admin) }
  let!(:pundit_context) { super_admin }
  let!(:mairie_compte) { MairieCompte.new }

  context "Permitted actions for super_admin" do
    it_behaves_like "permit actions", :mairie_compte, :index?, :new?, :create?
    it_behaves_like "not permit actions", :mairie_compte, :show?, :edit?, :update?, :destroy?
  end

  context "permitted actions for support" do
    let!(:pundit_context) { create(:super_admin, :support) }

    it_behaves_like "permit actions", :mairie_compte, :index?, :new?, :create?
    it_behaves_like "not permit actions", :mairie_compte, :show?, :edit?, :update?, :destroy?
  end
end
