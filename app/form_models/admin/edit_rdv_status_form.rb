class Admin::EditRdvStatusForm
  include ActiveModel::Model
  include Admin::RdvDuplicatesFormConcern
  include Pundit::Authorization

  attr_accessor :rdv, :agent_context

  delegate :errors, to: :rdv

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
