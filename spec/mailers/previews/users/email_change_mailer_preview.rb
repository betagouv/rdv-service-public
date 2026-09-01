class Users::EmailChangeMailerPreview < ActionMailer::Preview
  def confirmation_code
    login_code = LoginCode.new(
      email: "jean@moustache.fr",
      code: "394522",
      domain_id: "RDV_SERVICE_PUBLIC",
      created_at: 10.minutes.ago
    )
    login_code.readonly!
    Users::EmailChangeMailer.with(login_code:).confirmation_code
  end
end
