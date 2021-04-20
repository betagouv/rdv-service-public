class RemoveDeprecatedAbsencesAndPlagesOuvertures < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.logger = nil # disable AR logs

    Agent.where.not(deleted_at: nil).includes(:organisations).each do |agent|
      agent.organisations.each do |organisation|
        Rails.logger.debug "delete_agent;#{agent.full_name};#{organisation.name}"
        AgentRemoval.new(agent, organisation).remove!
      end
    end

    PlageOuverture.all.each do |plage_ouverture|
      next if plage_ouverture.agent.organisation_ids.include?(plage_ouverture.organisation_id)

      Rails.logger.debug "delete_plage_ouverture;#{plage_ouverture.id};#{plage_ouverture.agent.full_name};#{plage_ouverture.organisation.name}"
      plage_ouverture.destroy!
    end

    Absence.all.each do |absence|
      next if absence.agent.organisation_ids.include?(absence.organisation_id)

      Rails.logger.debug "delete_absence;#{absence.id};#{absence.agent.full_name};#{absence.organisation.name}"
      absence.destroy!
    end
  end
end
