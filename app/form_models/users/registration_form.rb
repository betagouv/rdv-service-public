class Users::RegistrationForm
  include ActiveModel::Model

  attr_reader :user
  delegate :first_name, :last_name, :password, :email, :phone_number, to: :user
  # these delegates are necessary for redirect after signup
  delegate :persisted?, :active_for_authentication?, :inactive_message, to: :user

  validates :email, presence: true
  validates :password, presence: true

  def initialize(attributes)
    @user = User.new(attributes)
  end

  def save
    user.save if valid?
  end

  def valid?
    [super, user.valid?].all?
  end

  def errors
    e = super.deep_dup
    e.copy!(user.errors)
    e
  end
end
