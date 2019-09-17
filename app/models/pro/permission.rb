class Pro::Permission
  include ActiveModel::Model

  attr_accessor :pro
  validates :pro, :role, :service_id, presence: true
  delegate :id, :new_record?, :persisted?, :role, :service_id, :update, to: :pro
end
