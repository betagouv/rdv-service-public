class Admin::EditRdvForm
  include ActiveModel::Model
  include Admin::RdvFormConcern

  def initialize(rdv, agent)
    @rdv = rdv
    @agent = agent
  end

  def submit(rdv_attributes)
    @rdv.update_and_notify(agent, rdv_attributes) do |rdv_before_save|
      @rdv = rdv_before_save
      Agent::RdvPolicy.new(agent, rdv).update? && valid?
    end
  end
end
