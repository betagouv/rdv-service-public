class Agents::LoginCodeForm
  def self.resend_login_code!(email, current_domain)
    UnblockBrevoTransactionalContact.new(email).call
    Agents::LoginCodeSender.perform(email:, domain_id: current_domain.id)
  end

  def initialize(email:, code:)
    @email = email
    @code = code
  end

  attr_reader :email, :code, :existing_login_code

  def submit!
    validator = LoginCodeValidator.new(email:, code:)

    valid = validator.valid?

    if valid
      validator.valid_login_code.update!(used_at: Time.zone.now)
    else
      @existing_login_code = LoginCode.most_recent_usable_for(email:)
      @existing_login_code&.errors&.add(:base, validator.error)
    end

    valid
  end
end
