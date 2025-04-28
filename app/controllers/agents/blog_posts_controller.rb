class Agents::BlogPostsController < AgentAuthController
  layout "modal"

  respond_to :html

  def index
    skip_policy_scope
    @feed = Blog::Feed.load
  end
end
