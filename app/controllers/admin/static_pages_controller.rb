class Admin::StaticPagesController < AgentAuthController
  def support
    skip_authorization
  end
end
