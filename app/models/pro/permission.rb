class Pro::Permission
  include ActiveModel::Model

  attr_accessor :pro
  validates :pro, :role, presence: true
  delegate :id, :new_record?, :persisted?, :role, :update, to: :pro
end
