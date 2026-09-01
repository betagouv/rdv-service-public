class Users::EmailChangeMailer < ApplicationMailer
  attr_reader :domain

  def confirmation_code
    @login_code = params[:login_code]
    @domain = Domain.find(@login_code.domain_id)

    mail(
      subject: "Votre code de confirmation est #{@login_code.code}",
      to: @login_code.email
    )
  end
end
