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

    agent_ids = rdv_attributes.delete(:agent_ids) # évite de sauvegarder les changements d’agents avant la validation
    @rdv.assign_attributes(rdv_attributes)

    (agent_ids - rdv.agent_ids).each { @rdv.agents_rdvs.build(agent_id: _1) }
    # TODO: do the same thing in memory for deleted agents
    # (rdv.agent_ids - agent_ids).each { @rdv.agents_rdvs.build(agent_id: _1) }
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
