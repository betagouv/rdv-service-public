RSpec.describe Agents::Blog::PostsController, "#index" do
  let!(:agent) { create(:agent) }

  before { sign_in agent }

  it "displays all posts" do
    post = create(:blog_post, title: "Un titre de post", content_truncated_text: "Un résumé de post")
    get agents_blog_posts_path

    expect(response.body).to include("Un titre de post")
    expect(response.body).to include("Un résumé de post")
    expect(response.body).to include(blog_post_path(post))
  end

  it "updates the agent's blog_read_at" do
    expect do
      get agents_blog_posts_path
    end.to change { agent.reload.blog_read_at }
  end

  context "when no posts in DB" do
    it "declares that no posts were found" do
      get agents_blog_posts_path
      expect(response.body).to include("Aucune nouveauté")
    end
  end
end
