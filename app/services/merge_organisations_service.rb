class MergeOrganisationsService
  include ActiveModel::Validations

  validate :agents_access_level_match

  def initialize(source_organisation:, target_organisation:)
    @source_organisation = source_organisation
    @target_organisation = target_organisation
  end

  def perform
    migrate_agents
    migrate_users
    migrate_exports
    migrate_lieux
    migrate_receipts
  end

  private

  def migrate_agents
    @source_organisation.agents.each do |agent|
      role_in_source_org = AgentRole.find_by(agent: agent, organisation: @source_organisation)
      role_in_target_org = AgentRole.find_by(agent: agent, organisation: @target_organisation)
      if role_in_target_org
        if role_in_target_org.access_level == role_in_source_org.access_level
          Rails.logger.info("Agent #{agent.id} already exists in target org: nothing to do.")
        else
          raise "Agent #{agent.id} seem to have different access levels despite the validation"
        end
      else
        AgentRole.create!(agent: agent, organisation: @target_organisation, access_level: role_in_source_org.access_level)
      end
      AgentRole.where(id: role_in_source_org.id).delete_all
    end
  end

  def migrate_users
    users_in_source_org = @source_organisation.users.ids.to_set
    users_in_target_org = @target_organisation.users.ids.to_set
    users_in_both = users_in_source_org.intersection(users_in_target_org)
    users_only_in_source_org = users_in_source_org.difference(users_in_target_org)

    UserProfile.where(organisation: @source_organisation, user_id: users_in_both).delete_all
    UserProfile.where(organisation: @source_organisation, user_id: users_only_in_source_org).update_all(organisation_id: @target_organisation.id) # rubocop:disable Rails/SkipsModelValidations
  end

  def migrate_exports
    Export.for_organisation(@source_organisation).destroy_all
  end

  def migrate_lieux
    @source_organisation.lieux.update_all(organisation_id: @target_organisation.id) # rubocop:disable Rails/SkipsModelValidations
  end

  def migrate_receipts
    @source_organisation.receipts.update_all(organisation_id: @target_organisation.id) # rubocop:disable Rails/SkipsModelValidations
  end

  def agents_access_level_match
    agents_in_both_orgs = @source_organisation.agents.to_a.intersection(@target_organisation.agents.to_a)
    agents_in_both_orgs.each do |agent|
      role_in_source_org = AgentRole.find_by(agent: agent, organisation: @source_organisation)
      role_in_target_org = AgentRole.find_by(agent: agent, organisation: @target_organisation)

      next unless role_in_target_org.access_level != role_in_source_org.access_level

      error_message = <<~ERROR
        L'agent #{agent.full_name} (ID=#{agent.id}) a un rôle #{role_in_source_org.access_level} dans #{@source_organisation.name}
        mais un rôle #{role_in_target_org.access_level} dans #{@target_organisation.name}
      ERROR
      errors.add(:base, error_message)
    end
  end
end
