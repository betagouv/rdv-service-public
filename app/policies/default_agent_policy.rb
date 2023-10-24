# frozen_string_literal: true

class DefaultAgentPolicy < ApplicationPolicy
  alias context pundit_user
  # define current_agent and current_organisation
  delegate :agent, :organisation, :agent_role, to: :context, prefix: :current

  def index?
    false
  end

  def show?
    same_agent_or_has_access?
  end

  def create?
    same_agent_or_has_access?
  end

  def cancel?
    same_agent_or_has_access?
  end

  def new?
    create?
  end

  def update?
    same_agent_or_has_access?
  end

  def edit?
    update?
  end

  def destroy?
    same_agent_or_has_access?
  end

  def versions?
    same_agent_or_has_access?
  end

  def same_org?
    return false if current_organisation.nil?

    if @record.is_a? Agent
      @record.roles.map(&:organisation_id) # works for unpersisted agents
    elsif @record.respond_to?(:organisation_id)
      @record.organisation_id == current_organisation.id
    elsif @record.respond_to?(:organisation_ids)
      @record.organisation_ids.include?(current_organisation.id)
    else
      false
    end
  end

  def same_service?
    if @record.respond_to?(:services)
      raise "used by #{@record.class.name}"
    elsif @record.respond_to?(:service)
      @record.service.in?(current_agent.services)
    elsif @record.respond_to?(:agent_id)
      @record.agent.service_id == current_agent.service_id
    elsif @record.respond_to?(:agent_ids)
      raise "still used by #{@record.class.name}"
      Agent.where(id: @record.agent_ids).pluck(:service_id).uniq == [current_agent.service_id]
    end
  end

  def same_agent?
    if @record.is_a? Agent
      @record.id == current_agent.id
    elsif @record.respond_to?(:agent_id)
      @record.agent_id == current_agent.id
    elsif @record.respond_to?(:agent_ids)
      @record.agent_ids.include?(current_agent.id)
    else
      false
    end
  end

  delegate :admin?, to: :current_agent_role

  def admin_and_same_org?
    admin? && same_org?
  end

  def same_agent_or_has_access?
    if same_agent?
      true
    elsif same_org?
      same_service? || context.can_access_others_planning?
    else
      false
    end
  end

  class Scope < Scope
    alias context pundit_user
    # define current_agent and current_organisation
    delegate :agent, :organisation, :agent_role, to: :context, prefix: :current

    def resolve
      scope.where(agent_id: current_agent.id, organisation_id: current_organisation.id)
    end
  end
end
