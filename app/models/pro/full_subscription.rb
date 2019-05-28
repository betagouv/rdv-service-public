class Pro::FullSubscription
  include ActiveModel::Model

  attr_accessor :pro, :first_name, :last_name
  validates :first_name, :last_name, presence: true

  def save
    build_pro
    valid? && pro.save
  end

  private

  def build_pro
    pro.first_name = first_name
    pro.last_name = last_name
  end
end
