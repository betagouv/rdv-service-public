class Agents::Blog::PostsController < AgentAuthController
  layout "modal"

  respond_to :html

  def index
    skip_policy_scope
    @feed = Blog::Feed.instance

    if @feed.available?
      current_agent.update_columns(blog_read_at: @feed.latest_post_at) # rubocop:disable Rails/SkipsModelValidations
    else
      head :service_unavailable
    end
  end
end
