RSpec.describe BlogPost do
  describe "#new_content_for_agent?" do
    subject(:new_content_for_agent?) { described_class.new_content_for_agent?(agent) }

    context "when no post in db" do
      context "when agent has never read the blog posts" do
        let(:agent) { Agent.new(blog_read_at: nil) }

        it { is_expected.to be(false) }
      end

      context "when agent has read the news before (somehow)" do
        let(:agent) { Agent.new(blog_read_at: 2.minutes.ago) }

        it { is_expected.to be(false) }
      end
    end

    context "when there is a post in db" do
      before { create(:blog_post, published_at: 5.hours.ago) }

      context "when agent has never read the blog posts" do
        let(:agent) { Agent.new(blog_read_at: nil) }

        it { is_expected.to be(true) }
      end

      context "when agent has read the news before the new post was published" do
        let(:agent) { Agent.new(blog_read_at: 8.days.ago) }

        it { is_expected.to be(true) }
      end

      context "when agent has read the news after the new post was published" do
        let(:agent) { Agent.new(blog_read_at: 2.minutes.ago) }

        it { is_expected.to be(false) }
      end
    end
  end

  describe "#refresh_from_posts" do
    context "when no post in db" do
      it "creates all passed posts" do
        new_posts = [
          attributes_for(:blog_post, title: "Première nouvelle"),
          attributes_for(:blog_post, title: "Seconde nouvelle"),
        ]
        expect { described_class.refresh_from_posts(new_posts) }.to change(described_class, :count).from(0).to(2)
        expect(described_class.pluck(:title)).to contain_exactly("Première nouvelle", "Seconde nouvelle")
      end
    end

    context "when posts already exist in db" do
      let!(:existing_post) { create(:blog_post, title: "Nouvelle existante") }

      it "replaces it with new posts" do
        new_posts = [
          attributes_for(:blog_post, title: "Première nouvelle"),
          attributes_for(:blog_post, title: "Seconde nouvelle"),
        ]
        expect { described_class.refresh_from_posts(new_posts) }.to change(described_class, :count).from(1).to(2)
        expect(described_class.pluck(:title)).to contain_exactly("Première nouvelle", "Seconde nouvelle")
        expect { existing_post.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
