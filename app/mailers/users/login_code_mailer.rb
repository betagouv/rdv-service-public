class Users::LoginCodeMailer < ApplicationMailer
  attr_reader :domain

  def send_login_code(email:, domain_id:)
    @email = email
    @domain = Domain.find(domain_id)
    @login_code = UserLoginCode.code_for(email)
    mail(
      subject: "Votre code de connexion est #{@login_code}",
      to: email
    )
  end
end
