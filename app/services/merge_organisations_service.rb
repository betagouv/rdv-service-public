# rubocop:disable Rails/SkipsModelValidations
class MergeOrganisationsService
  include ActiveModel::Validations

  validate :both_orgs_from_same_territory
  validate :motifs_are_compatible, on: :expect_identical_motifs
  validate :agents_access_level_match
  validate :webhooks_are_similar

  def initialize(source_organisation:, target_organisation:)
    @source_organisation = source_organisation
    @target_organisation = target_organisation
  end

  def perform
    raise "Can't perform merge if errors are present" if invalid?

    migrate_motifs
    migrate_rdvs
    migrate_agents
    migrate_users
    migrate_exports
    migrate_lieux
    migrate_receipts
    migrate_sector_attributions
    migrate_webhooks
  end

  private

  def migrate_motifs
    @source_organisation.motifs.active.each do |source_motif|
      existing_motif = source_motif.duplicates.find_by(organisation: @target_organisation)
      if existing_motif
        pair = MotifsComparisonPresenter::Pair.new(source_motif, existing_motif)
        if pair.mostly_identical?
          Rdv.where(motif_id: source_motif.id).update_all(motif_id: existing_motif.id)
          MotifsPlageOuverture.where(motif_id: source_motif.id).update_all(motif_id: existing_motif.id)
          source_motif.destroy!
        else
          raise "Motifs #{source_motif.id} and #{existing_motif.id} have some differences that should have been caught in validation"
        end
      else
        source_motif.update_columns(organisation_id: @target_organisation.id)
      end
    end
  end

  def migrate_rdvs
    @source_organisation.rdvs.update_all(organisation_id: @target_organisation.id)
  end

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
    UserProfile.where(organisation: @source_organisation, user_id: users_only_in_source_org).update_all(organisation_id: @target_organisation.id)
  end

  def migrate_exports
    Export.for_organisation(@source_organisation).destroy_all
  end

  def migrate_lieux
    @source_organisation.lieux.update_all(organisation_id: @target_organisation.id)
  end

  def migrate_receipts
    @source_organisation.receipts.update_all(organisation_id: @target_organisation.id)
  end

  def migrate_sector_attributions
    @source_organisation.sector_attributions.update_all(organisation_id: @target_organisation.id)
  end

  def migrate_webhooks
    @source_organisation.webhook_endpoints.each do |source_webhook|
      existing_webhook = @target_organisation.webhook_endpoints.find_by(target_url: source_webhook.target_url)
      if existing_webhook
        source_webhook.destroy!
      else
        source_webhook.update!(organisation_id: @target_organisation.id)
      end
    end
  end

  def both_orgs_from_same_territory
    if @source_organisation.territory != @target_organisation.territory
      errors.add(:base, "Les deux organisations doivent être dans le même territoire")
    end
  end

  def motifs_are_compatible
    @source_organisation.motifs.active.each do |source_motif|
      existing_motif = source_motif.duplicates.find_by(organisation: @target_organisation)
      next unless existing_motif

      differences = MotifsComparisonPresenter::Pair.new(source_motif, existing_motif).differences
      next unless differences.any?

      error_message = "Les motifs #{source_motif.id} et #{existing_motif.id} (#{source_motif.name}) sont des doublons mais ont les différences suivantes :\n"
      differences.each { |attr, values| error_message += "  #{attr}: - #{values[0].inspect} + #{values[1].inspect}\n" }
      errors.add(:base, error_message)
    end
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

  def webhooks_are_similar
    @source_organisation.webhook_endpoints.each do |source_webhook|
      existing_webhook = @target_organisation.webhook_endpoints.find_by(target_url: source_webhook.target_url)
      if existing_webhook && existing_webhook.subscriptions != source_webhook.subscriptions
        errors.add(:base, "Les webhooks #{source_webhook.id} et #{existing_webhook.id} ont la même URL mais des subscriptions différentes")
      end
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
