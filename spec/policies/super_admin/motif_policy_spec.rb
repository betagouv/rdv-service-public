describe SuperAdmin::MotifPolicy, type: :policy do
  subject { described_class }

  let!(:super_admin) { create(:super_admin) }
  let!(:pundit_context) { super_admin }
  let!(:motif) { create(:motif) }

  context "Permitted actions for super_admin" do
    it_behaves_like "permit actions", :motif, :index?, :show?, :new?, :create?, :edit?, :update?, :destroy?
  end

  context "permitted actions for support" do
    let!(:pundit_context) { create(:super_admin, :support) }

    it_behaves_like "permit actions", :motif, :index?, :show?
    it_behaves_like "not permit actions", :motif, :new?, :create?, :edit?, :update?, :destroy?
  end
end
