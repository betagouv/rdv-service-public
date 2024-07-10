class Admin::EditRdvForm
  include ActiveModel::Model
  include Admin::RdvFormConcern

  attr_accessor :agent_context

  def initialize(rdv, agent_context)
    @rdv = rdv
    @agent_context = agent_context
  end

  def update(**rdv_attributes)
    valid? && @rdv.update_and_notify(agent_context.agent, rdv_attributes)
  end
end
