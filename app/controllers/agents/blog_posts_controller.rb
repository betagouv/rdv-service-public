class Agents::BlogPostsController < AgentAuthController
  layout "modal"

  respond_to :html

  def index
    skip_policy_scope
    @feed = Blog::Feed.load
    current_agent.update_columns(blog_read_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
  end
end
