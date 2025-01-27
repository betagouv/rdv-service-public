class CreateMissingUserProfiles < ActiveRecord::Migration[7.1]
  def up
    participations = Participation
      .joins(:user, :rdv)
      .joins("LEFT JOIN user_profiles ON user_profiles.user_id = participations.user_id AND user_profiles.organisation_id = rdvs.organisation_id")
      .where(user_profiles: { id: nil }) # on veut les participations qui n'ont pas de user_profile associé
      .where(users: { deleted_at: nil }) # on exclut les usagers soft deleted
      .select("participations.user_id, rdvs.organisation_id") # ces trois lignes permettent de récupérer des paires uniques de user_id et organisation_id
      .order("participations.user_id, rdvs.organisation_id")
      .distinct
      .pluck("participations.user_id, rdvs.organisation_id")
    Rails.logger.info "\n\n---\n\nCréation de #{participations.size} user_profiles manquants...\n\n---\n\n"
    participations.each do |user_id, organisation_id|
      user = User.find(user_id)
      organisation = Organisation.find(organisation_id)
      Rails.logger.info "Création du user_profile pour #{user.full_name} (#{user.id}) dans l’orga #{organisation.name} (#{organisation.id})..."
      user.add_organisation(organisation)
    end
    Rails.logger.info "\n\n---\n\nFin !\n\n---\n\n"
  end
end
