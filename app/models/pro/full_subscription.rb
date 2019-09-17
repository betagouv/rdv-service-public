class Pro::FullSubscription
  include ActiveModel::Model

  attr_accessor :pro, :first_name, :last_name, :service_id
  validates :first_name, :last_name, :service_id, presence: true

  def save
    build_pro
    valid? && pro.save
  end

  private

  def build_pro
    pro.first_name = first_name
    pro.last_name = last_name
    pro.service_id = service_id
  end
end
