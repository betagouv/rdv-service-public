class Admin::EditRdvForm
  include ActiveModel::Model
  include Admin::RdvFormConcern
  include Pundit::Authorization

  attr_accessor :agent_context

  def initialize(rdv, agent_context)
    @rdv = rdv
    @agent_context = agent_context
  end

  def submit(rdv_attributes)
    @rdv.assign_attributes(rdv_attributes)

    authorize(@rdv, :update?, policy_class: Agent::RdvPolicy)

    if valid?
      @rdv.save_and_notify(agent_context.agent)
    else
      false
    end
  end

  private

  def pundit_user
    agent_context
  end
end
