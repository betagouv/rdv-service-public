class BlogPostsController < ApplicationController
  # Les images des posts sont hébergées sur docs.numerique.gouv.fr
  content_security_policy only: :show do |policy|
    policy.img_src(*policy.directives["img-src"], "https://docs.numerique.gouv.fr/media/")
  end

  def index
    @posts = BlogPost.order(published_at: :desc).page(params[:page]).per(20)
  end

  def show
    @post = BlogPost.find(params[:id])
  end
end
