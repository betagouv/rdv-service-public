class Pro::Permission
  include ActiveModel::Model

  attr_accessor :pro
  validates :pro, :role, :specialite_id, presence: true
  delegate :id, :new_record?, :persisted?, :role, :specialite_id, :update, to: :pro
end
