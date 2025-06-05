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
    @rdv.update_and_notify(agent_context.agent, rdv_attributes) do |rdv_before_save|
      authorize(rdv_before_save, :update?, policy_class: Agent::RdvPolicy)
      @rdv = rdv_before_save
      valid?
    end
  end

  private

  def pundit_user
    agent_context
  end
end
