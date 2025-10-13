RSpec.describe Agents::Blog::PostsController, "#index" do
  let!(:agent) { create(:agent) }

  before do
    stub_request(:get, Blog::Feed::HEADWAY_URL).to_return(body: file_fixture("headway_home.html"))
    sign_in agent
  end

  it "displays all posts" do
    get agents_blog_posts_path
    expect(response.body).to include("Mots de passe forts obligatoires")
  end

  it "updates the agent's blog_read_at" do
    expect do
      get agents_blog_posts_path
    end.to change { agent.reload.blog_read_at }
  end

  context "when posts can't be fetched" do
    before do
      stub_request(:get, Blog::Feed::HEADWAY_URL).to_timeout
    end

    it "returns a response error" do
      get agents_blog_posts_path
      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
