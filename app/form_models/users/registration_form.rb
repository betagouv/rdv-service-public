class Users::RegistrationForm
  include ActiveModel::Model

  attr_reader :user

  delegate :first_name, :last_name, :email, :phone_number, :email_tld, to: :user
  # these delegates are necessary for redirect after signup
  delegate :persisted?, :active_for_authentication?, :inactive_message, to: :user

  validates :email, presence: true

  def initialize(attributes)
    @user = User.new(attributes)
    @user.created_through = "user_sign_up"
  end

  def save
    if valid?
      user.save
    else
      # I'd rather override the errors method but it's incredibly tricky
      user.errors.each { |k, v| errors.add(k, v) }
    end
  end

  def valid?
    [super, user.valid?].all?
  end
end
