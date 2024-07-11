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
      @rdv.save_and_notify(agent_context.agent)
    else
      false
    end
  end
end
