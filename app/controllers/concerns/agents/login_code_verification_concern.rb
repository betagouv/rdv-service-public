module Agents::LoginCodeVerificationConcern
  extend ActiveSupport::Concern

  def resend_login_code!(email)
    UnblockBrevoTransactionalContact.new(email).call
    Agents::LoginCodeSender.perform(email:, domain_id: current_domain.id)
  end

  def submit_login_code!(email)
    code = params.require(:login_code).expect(:code)
    validator = LoginCodeValidator.new(email:, code:)

    if validator.valid?
      validator.valid_login_code.update!(used_at: Time.zone.now)
      yield
    else
      @email = email
      @existing_login_code = LoginCode.most_recent_usable_for(email:)
      @existing_login_code&.errors&.add(:base, validator.error)
      render :new
    end
  end
end
