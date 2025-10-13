class Agents::Blog::PostsController < AgentAuthController
  layout "modal"

  respond_to :html

  def index
    skip_policy_scope
    @posts = BlogPost.all
    current_agent.update_columns(blog_read_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
  end
end
