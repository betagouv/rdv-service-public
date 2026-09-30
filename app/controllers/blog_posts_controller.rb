class BlogPostsController < ApplicationController
  def index
    @posts = BlogPost.order(published_at: :desc).page(params[:page]).per(20)
  end

  def show
    @post = BlogPost.find(params[:id])
  end
end
