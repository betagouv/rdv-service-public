module Agents::LoginCodeForm
  def resend_login_code!(email, current_domain)
    UnblockBrevoTransactionalContact.new(email).call
    Agents::LoginCodeSender.perform(email:, domain_id: current_domain.id)
  end

  def submit_login_code!(email, failure_template: :new)
    code = params.require(:login_code).expect(:code)
    validator = LoginCodeValidator.new(email:, code:)

    if validator.valid?
      validator.valid_login_code.update!(used_at: Time.zone.now)
      yield
    else
      @email = email
      @existing_login_code = LoginCode.most_recent_usable_for(email:)
      @existing_login_code&.errors&.add(:base, validator.error)
      render failure_template
    end
  end
end
