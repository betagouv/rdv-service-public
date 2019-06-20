class Pro::FullSubscription
  include ActiveModel::Model

  attr_accessor :pro, :first_name, :last_name, :specialite_id
  validates :first_name, :last_name, :specialite_id, presence: true

  def save
    build_pro
    valid? && pro.save
  end

  private

  def build_pro
    pro.first_name = first_name
    pro.last_name = last_name
    pro.specialite_id = specialite_id
  end
end
