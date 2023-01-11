# frozen_string_literal: true

class Users::RegistrationForm
  include ActiveModel::Model

  attr_reader :user

  delegate :first_name, :last_name, :email, :phone_number, :email_tld, to: :user
  # these delegates are necessary for redirect after signup
  delegate :persisted?, :active_for_authentication?, :inactive_message, to: :user

  validates :email, presence: true

  # @param domain This is our only way of passing the domain to the mailer that sends the confirmation email
  def initialize(attributes, domain:)
    @user = User.new(attributes)
    @user.created_through = "user_sign_up"
    @user.sign_up_domain = domain
  end

  def save
    if valid?
      user.save
    else
      # I'd rather override the errors method but it's incredibly tricky
      user.errors.each { |error| errors.add(error.attribute, error.message) }
    end
  end

  def valid?
    [super, user.valid?].all?
  end
end
