class CleanupSoftDeletedAgentsAssociations < ActiveRecord::Migration[7.0]
  def up
    PaperTrail.request(whodunnit: "Une migration dans le cadre de #3939") do
      Agent.where.not(deleted_at: nil).find_each do |agent|
        raise "agent still has attached orgs: #{agent.organisations.ids.inspect}" if agent.organisations.any?

        agent.absences.destroy_all
        agent.plage_ouvertures.destroy_all
        agent.agent_services.destroy_all
        agent.agent_territorial_access_rights.destroy_all
        agent.territorial_roles.destroy_all
        agent.agent_teams.destroy_all
        agent.referent_assignations.destroy_all
        agent.sector_attributions.destroy_all
      end
    end
  end

  def down
    Rails.logger.warn "Can't revert data deletion"
  end
end
