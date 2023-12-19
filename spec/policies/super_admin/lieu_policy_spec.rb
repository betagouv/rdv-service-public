describe SuperAdmin::LieuPolicy, type: :policy do
  subject { described_class }

  let!(:super_admin) { create(:super_admin) }
  let!(:pundit_context) { super_admin }
  let!(:lieu) { create(:lieu) }

  context "Permitted actions for super_admin" do
    it_behaves_like "permit actions", :lieu, :index?, :show?, :new?, :create?, :edit?, :update?, :destroy?
  end

  context "permitted actions for support" do
    let!(:pundit_context) { create(:super_admin, :support) }

    it_behaves_like "permit actions", :lieu, :index?, :show?, :edit?, :update?
    it_behaves_like "not permit actions", :lieu, :new?, :create?, :destroy?
  end
end
