# frozen_string_literal: true

class AddForeignKeys < ActiveRecord::Migration[7.0]
  # rubocop:disable Metrics/MethodLength
  def change
    up_only do
      MotifsPlageOuverture.where.not(plage_ouverture_id: PlageOuverture.all.select(:id)).delete_all

      # This is much much faster that a subquery
      user_ids = User.unscope(:where).pluck(:id).to_set
      user_profiles_users_ids = UserProfile.distinct.pluck(:user_id).to_set
      broken_references = user_profiles_users_ids - user_ids
      UserProfile.where(user_id: broken_references).delete_all
    end

    add_foreign_key :agent_roles, :agents
    add_foreign_key :agent_roles, :organisations
    add_foreign_key :agent_teams, :teams
    add_foreign_key :agent_teams, :agents
    add_foreign_key :agent_territorial_roles, :agents
    add_foreign_key :agent_territorial_roles, :territories
    add_foreign_key :agents_rdvs, :agents
    add_foreign_key :agents_rdvs, :rdvs
    add_foreign_key :motif_categories_territories, :motif_categories
    add_foreign_key :motif_categories_territories, :territories
    add_foreign_key :motifs_plage_ouvertures, :motifs
    add_foreign_key :motifs_plage_ouvertures, :plage_ouvertures
    add_foreign_key :organisations, :territories
    add_foreign_key :receipts, :rdvs
    add_foreign_key :receipts, :users
    add_foreign_key :referent_assignations, :users
    add_foreign_key :referent_assignations, :agents
    add_foreign_key :sectors, :territories
    add_foreign_key :rdvs_users, :rdvs
    add_foreign_key :rdvs_users, :users
    add_foreign_key :teams, :territories
    add_foreign_key :sector_attributions, :sectors
    add_foreign_key :user_profiles, :organisations
    add_foreign_key :user_profiles, :users
    add_foreign_key :zones, :sectors
  end
  # rubocop:enable Metrics/MethodLength
end
