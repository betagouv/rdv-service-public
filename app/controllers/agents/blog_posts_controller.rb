class Agents::BlogPostsController < AgentAuthController
  layout "modal"

  respond_to :html

  def index
    skip_policy_scope
    @feed = Blog::Feed.instance
    @feed.agent_up_to_date!(current_agent)
  end
end
