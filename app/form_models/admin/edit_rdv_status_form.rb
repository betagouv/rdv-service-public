class Admin::EditRdvStatusForm
  include ActiveModel::Model
  include Admin::RdvDuplicatesFormConcern

  attr_accessor :rdv

  delegate :errors, to: :rdv

  def initialize(rdv, current_agent)
    @rdv = rdv
    @current_agent = current_agent
  end

  def submit(rdv_attributes)
    if valid?
      Rdv::UpdateStatusAndNotify.new(@rdv, @current_agent, status: rdv_attributes["status"]).perform
    end
  end
end
