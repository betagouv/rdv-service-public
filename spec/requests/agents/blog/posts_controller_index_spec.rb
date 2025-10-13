RSpec.describe Agents::Blog::PostsController, "#index" do
  let!(:agent) { create(:agent) }

  before { sign_in agent }

  it "displays all posts" do
    create(:blog_post, title: "Un titre de post", description: "Une description de post", link: "https://example.com")
    get agents_blog_posts_path

    expect(response.body).to include("Un titre de post")
    expect(response.body).to include("Une description de post")
    expect(response.body).to include("https://example.com")
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
