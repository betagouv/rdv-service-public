RSpec.describe "SuperAdmins::Organisations", type: :request do
  include Rails.application.routes.url_helpers

  let(:super_admin) { create(:super_admin) }

  before { login_as(super_admin, scope: :super_admin) }

  describe "PATCH /super_admins/organisations/:id" do
    let!(:cni_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
    let!(:passport_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
    let!(:cni_passport_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME) }

    context "quand ants_connectable passe de false à true" do
      let(:organisation) { create(:organisation, ants_connectable: false) }

      it "ajoute les catégories ANTS au territoire" do
        patch super_admins_organisation_path(organisation), params: { organisation: { ants_connectable: true } }

        expect(organisation.territory.reload.motif_categories).to contain_exactly(cni_category, passport_category, cni_passport_category)
      end
    end

    context "quand ants_connectable reste à true" do
      let(:organisation) { create(:organisation, ants_connectable: true) }

      it "n'ajoute pas les catégories ANTS au territoire une deuxième fois" do
        organisation.territory.motif_categories = [cni_category, passport_category, cni_passport_category]

        patch super_admins_organisation_path(organisation), params: { organisation: { ants_connectable: true } }

        expect(organisation.territory.reload.motif_categories.count).to eq(3)
      end
    end

    context "quand un autre attribut change" do
      let(:organisation) { create(:organisation, ants_connectable: false) }

      it "n'ajoute pas les catégories ANTS au territoire" do
        patch super_admins_organisation_path(organisation), params: { organisation: { name: "Changement" } }

        expect(organisation.territory.reload.motif_categories).to be_empty
      end
    end
  end
end
