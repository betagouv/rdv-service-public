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
    @rdv.assign_attributes(rdv_attributes)

    if valid?
      @rdv.update_with_notifs(agent_context.agent, rdv_attributes)
    else
      Rdv::Updatable::Result.new(success: false)
    end
  end

  def save
    raise NotImplementedError
  end
end
