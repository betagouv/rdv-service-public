class Admin::EditRdvForm
  include ActiveModel::Model
  include Admin::RdvFormConcern

  attr_accessor :agent_context

  delegate :agent, to: :agent_context

  def initialize(rdv, agent_context)
    @rdv = rdv
    @agent_context = agent_context
  end

  def submit(rdv_attributes)
    @rdv.update_and_notify(agent, rdv_attributes) do |rdv_before_save|
      @rdv = rdv_before_save
      Agent::RdvPolicy.new(agent, rdv).update? && valid?
    end
  end
end
