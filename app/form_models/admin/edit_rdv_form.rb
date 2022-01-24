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
    RdvUpdater.update(agent_context.agent, rdv, rdv_attributes)
  end

  def save
    raise NotImplementedError
  end
end
