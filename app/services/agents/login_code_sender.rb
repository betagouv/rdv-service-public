class Agents::LoginCodeSender
  def self.perform(email:, domain_id:, resend: false)
    return if LoginCode.most_recent_usable_for(email:)&.very_recent?

    UnblockBrevoTransactionalContact.new(email).call if resend
    login_code = LoginCode.create!(email:, domain_id:)
    Agents::LoginCodeMailer.with(login_code:).login_code.deliver_later
  end
end
