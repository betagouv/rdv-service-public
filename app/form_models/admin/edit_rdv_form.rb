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
    raise ArgumentError, "agent_ids est accepté mais pas agents" if rdv_attributes.key?(:agents)

    previous_agent_ids = @rdv.agent_ids

    @rdv.assign_attributes(rdv_attributes)

    @selected_agent_ids = @rdv.agent_ids

    authorize(@rdv, :update?, policy_class: Agent::RdvPolicy)

    if valid?
      @rdv.save_and_notify(agent_context.agent)
    else
      @rdv.agent_ids = previous_agent_ids
      false
    end
  end

  attr_reader :selected_agent_ids

  private

  def pundit_user
    agent_context
  end
end
