class Agent::FullSubscription
  include ActiveModel::Model

  attr_accessor :agent, :first_name, :last_name, :service_id
  validates :first_name, :last_name, :service_id, presence: true

  def save
    build
    valid? && agent.save
  end

  private

  def build
    agent.first_name = first_name
    agent.last_name = last_name
    agent.service_id = service_id
  end
end
