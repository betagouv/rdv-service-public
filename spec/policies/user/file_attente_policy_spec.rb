RSpec.describe User::FileAttentePolicy, type: :policy do
  subject { described_class }

  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:pundit_context) { user }
  let(:relative) do
    create(:user, :relative, responsible: user, first_name: "Petit", last_name: "Bébé")
  end
  let!(:rdv) { create(:rdv, organisation: organisation, agents: [agent], users: [user]) }

  context "quand la file d'attente appartient à l'utilisateur, sur son propre rdv" do
    let(:file_attente) { build(:file_attente, rdv: rdv, user: user) }

    it_behaves_like "permit actions", :file_attente, :create_or_delete?
  end

  context "quand la file d'attente appartient à un proche, sur le rdv de ce proche" do
    let(:rdv) { create(:rdv, organisation: organisation, agents: [agent], users: [relative]) }
    let(:file_attente) { build(:file_attente, rdv: rdv, user: relative) }

    it_behaves_like "permit actions", :file_attente, :create_or_delete?
  end

  context "quand la file d'attente appartient à un autre utilisateur" do
    let(:file_attente) { build(:file_attente, rdv: rdv, user: user2) }

    it_behaves_like "not permit actions", :file_attente, :create_or_delete?
  end

  context "quand le rdv appartient à un autre utilisateur, même avec le user_id de current_user" do
    let(:other_rdv) { create(:rdv, organisation: organisation, agents: [agent], users: [user2]) }
    let(:file_attente) { build(:file_attente, rdv: other_rdv, user: user) }

    it_behaves_like "not permit actions", :file_attente, :create_or_delete?
  end

  context "quand le rdv de la file d'attente a été supprimé entre-temps" do
    let(:file_attente) { build(:file_attente, rdv: nil, user: user) }

    it_behaves_like "not permit actions", :file_attente, :create_or_delete?
  end
end
