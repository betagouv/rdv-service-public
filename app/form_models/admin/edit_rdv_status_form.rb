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
    @rdv.update_and_notify(@current_agent, rdv_attributes) do |rdv_before_save|
      @rdv = rdv_before_save
      valid?
    end
  end
end
