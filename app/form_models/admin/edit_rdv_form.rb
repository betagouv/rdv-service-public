# frozen_string_literal: true

class Admin::EditRdvForm
  include ActiveModel::Model
  include Admin::RdvFormConcern

  attr_accessor :agent_context

  def initialize(rdv, agent_context)
    @rdv = rdv
    @agent_context = agent_context
  end

  def update(**rdv_attributes)
    # assigning attributes on rdv in order to validate this form object
    @rdv.assign_attributes(rdv_attributes)
    # we want to confirm eventual warnings at both Rdv level and current Form object
    @active_warnings_confirm_decision = rdv_attributes[:active_warnings_confirm_decision]
    valid? && RdvUpdater.update(agent_context.agent, rdv, rdv_attributes)
  end

  def save
    raise NotImplementedError
  end
end
