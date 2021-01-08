class Agent::Permission
  include ActiveModel::Model

  attr_accessor :agent

  validates :agent, :role, :service_id, presence: true
  delegate :id, :new_record?, :persisted?, :role, :service_id, :organisation_ids, :errors, :update, to: :agent
end
