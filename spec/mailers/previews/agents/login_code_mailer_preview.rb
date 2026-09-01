class Agents::LoginCodeMailerPreview < ActionMailer::Preview
  def login_code
    login_code = LoginCode.new(
      email: "jean@agent.fr",
      code: "394522",
      domain_id: "RDV_SERVICE_PUBLIC",
      created_at: 10.minutes.ago
    )
    login_code.readonly!
    Agents::LoginCodeMailer.with(login_code:).login_code
  end
end
