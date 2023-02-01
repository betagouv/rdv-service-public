# frozen_string_literal: true

describe Admin::Territories::MotifCategoriesController, type: :controller do
  describe "#update" do
    it "responds redirect" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      sign_in agent
      post :update, params: { territory_id: territory.id, territory: { motif_category_ids: nil } }
      expect(response).to redirect_to(edit_admin_territory_motif_fields_path(territory))
    end

    it "update territory" do
      create_list(:motif_category, 5)
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      random_categories_ids = MotifCategory.all.sample(3).map(&:id)
      sign_in agent

      expect do
        post :update, params: { territory_id: territory.id, territory: { motif_category_ids: random_categories_ids } }
      end.to change { territory.reload.motif_categories.count }.from(0).to(3)
    end
  end
end
