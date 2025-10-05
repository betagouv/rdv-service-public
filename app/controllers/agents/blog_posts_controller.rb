class Agents::BlogPostsController < AgentAuthController
  layout "modal"

  respond_to :html

  def index
    skip_policy_scope

    @feed = Blog::Feed.from_cache

    if @feed.latest_post_at > current_agent.blog_read_at
      current_agent.update_columns(blog_read_at: @feed.latest_post_at) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
