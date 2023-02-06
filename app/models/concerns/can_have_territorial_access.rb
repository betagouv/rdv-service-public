# frozen_string_literal: true

module CanHaveTerritorialAccess
  extend ActiveSupport::Concern

  def territorial_admin!(territory)
    AgentTerritorialRole.find_or_create_by!(territory: territory, agent: self)
  end

  def remove_territorial_admin!(territory)
    territorial_role_in(territory)&.delete
  end
end
