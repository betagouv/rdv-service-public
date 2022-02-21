# frozen_string_literal: true

class Configuration::TerritoryPolicy

  def initialize(context, territory)
    @context = context
    @territory = territory
  end

  def show?
    @context.agent.territorial_admin_in?(@territory)
  end

  def allow_to_manage_access_right?
    @context.agent.territorial_admin_in?(@territory)
  end

  def allow_to_manage_webhook_endpoints?
    @context.agent.territorial_admin_in?(@territory)
  end

  def allow_to_manage_sms_provider?
    @territory.has_own_sms_provider && @context.agent.territorial_admin_in?(@territory)
  end

  def allow_to_manage_sectorization?
    @context.agent.territorial_admin_in?(@territory)
  end
end
