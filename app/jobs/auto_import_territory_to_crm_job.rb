# Catégorisation et import CRM automatique des espaces self-onboardés de l'État

class AutoImportTerritoryToCrmJob < ApplicationJob
  def perform(territory_id)
    return unless ENV["NOTION_API_SECRET"]

    territory = Territory.find(territory_id)
    return if territory.category.present?

    papertrail_version = territory.versions.where(event: "create").first&.whodunnit
    return unless papertrail_version

    agent = Agent.agent_from_whodunnit(papertrail_version)
    return unless agent

    if agent.email&.ends_with?(".gouv.fr") && !VerifiedServicePublicDomainNames.france_service?(agent.email)
      territory.update!(category: "État")
      CreateCrmPageJob.perform_later(territory.id)
    end
  end
end
