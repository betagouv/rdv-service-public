RSpec.describe "Blog posts", type: :request do
  describe "GET /nouveautes" do
    it "lists the posts, most recent first, with links to each post" do
      old_post = create(:blog_post, title: "Ancienne nouveauté", published_at: 2.months.ago)
      recent_post = create(:blog_post, title: "Nouveauté récente", published_at: 1.day.ago)

      get "/nouveautes"

      expect(response).to have_http_status(:ok)
      expect(response.body.index("Nouveauté récente")).to be < response.body.index("Ancienne nouveauté")
      expect(response.body).to include(blog_post_path(recent_post), blog_post_path(old_post))
    end

    it "is accessible without being signed in and handles the absence of posts" do
      get "/nouveautes"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Aucune nouveauté pour le moment")
    end
  end

  describe "GET /nouveautes/:id" do
    let(:docs_document_id) { SecureRandom.uuid }
    let!(:post) do
      create(:blog_post, title: "Un titre de post", description: "Une description de post", external_url: "https://docs.numerique.gouv.fr/docs/#{docs_document_id}")
    end

    it "displays the post, using the Docs document id in the URL" do
      get "/nouveautes/#{docs_document_id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Un titre de post", "Une description de post", post.external_url)
    end

    it "keeps the same URL after the posts are refreshed from Docs" do
      BlogPost.refresh_from_posts([build(:blog_post, title: "Un titre de post", external_url: post.external_url)])

      get "/nouveautes/#{docs_document_id}"

      expect(response).to have_http_status(:ok)
    end

    it "returns a 404 for an unknown post" do
      get "/nouveautes/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
