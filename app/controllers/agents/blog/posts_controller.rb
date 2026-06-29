class Agents::Blog::PostsController < AgentAuthController
  respond_to :turbo_stream

  def index
    skip_policy_scope
    @posts = BlogPost.order(published_at: :desc).limit(10)
    current_agent.update_columns(blog_read_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
  end
end
