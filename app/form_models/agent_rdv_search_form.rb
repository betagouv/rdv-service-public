class AgentRdvSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :start, :end, :date, :agent_id, :user_id, :page, :status, :default_period, :show_user_details

  # belongs_to :organisation, :agent

  def initialize(attributes)
    attributes[:date] = Date.parse(attributes[:date]) if attributes[:date].present?
    attributes[:start] = Date.parse(attributes[:start]) if attributes[:start].present?
    attributes[:end] = Date.parse(attributes[:end]) if attributes[:end].present?
    attributes[:show_user_details] = ["1", "true"].include?(attributes[:show_user_details])
    super(attributes)
  end

  def date_range_params
    return nil if start.blank? || self.end.blank?

    start..self.end
  end
end
