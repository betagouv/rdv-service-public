# frozen_string_literal: true

class Admin::NewRdvForm
  include ActiveModel::Model
  include Admin::RdvFormConcern

  attr_accessor :rdv, :agent_context

  def initialize(agent_context, attributes = {})
    @agent_context = agent_context
    @rdv = Rdv.new(attributes)
  end

  def valid?
    super && @rdv.valid? # order is important here
  end

  def save
    valid? && @rdv.save
  end
end
