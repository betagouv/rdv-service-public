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

    agent_ids = rdv_attributes.delete(:agent_ids) || [] # évite de sauvegarder les changements d’agents avant la validation
    @rdv.assign_attributes(rdv_attributes)

    # Add new_agent_rdvs_in_memory_but_not_in_the_database
    (agent_ids - rdv.agent_ids).each { @rdv.agents_rdvs.build(agent_id: _1) }

    # Remove agent_rdvs_in_memory_but_not_in_the_database
    (rdv.agent_ids - agent_ids).each do |agent_id_to_remove|
      @rdv.agents_rdvs.find do |agent_rdv|
        agent_rdv.agent_id == agent_id_to_remove.to_i
      end.mark_for_destruction
    end

    authorize(@rdv, :update?, policy_class: Agent::RdvPolicy)

    if valid?
      @rdv.save_and_notify(agent_context.agent)
    else
      false
    end
  end

  # TODO: utiliser cette méthode pour les autres endroits où ce formulaire existe
  def current_agent_ids
    rdv.agents_rdvs.to_a.reject(&:marked_for_destruction?).map(&:agent_id)
  end

  private

  def pundit_user
    agent_context
  end
end
