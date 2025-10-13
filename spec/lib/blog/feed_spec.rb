RSpec.describe Blog::Feed do
  let(:klass) { Class.new(described_class) }

  def expect_feed_loaded(instance)
    expect(instance.available?).to be(true)
    expect(instance.new_content_for_agent?(Agent.new)).to be(true)

    expect(instance.title).to eq("Nouveautés")
    expect(instance.link).to eq(Blog::Feed::HEADWAY_URL)
    expect(instance.latest_post_at).to eq(Time.zone.parse("2025-05-05 15:24:46"))
    expect(instance.posts.size).to eq(3)
  end

  def expect_feed_ko(instance)
    expect(instance.available?).to be(false)
    expect(instance.new_content_for_agent?(Agent.new)).to be(false)

    expect(instance.title).to be_nil
    expect(instance.link).to be_nil
    expect(instance.latest_post_at).to be_nil
    expect(instance.posts).to be_nil
  end

  context "when cache is empty" do
    context "when headway is unreachable" do
      before { stub_request(:get, Blog::Feed::HEADWAY_URL).to_timeout }

      it "is marked unavailable" do
        expect_feed_ko(klass.instance)
      end

      it "warns Sentry" do
        expect { klass.instance }.to change(sentry_events, :size).by(1)
        expect(sentry_events.last.exception.values.first.value).to eq("execution expired (Net::OpenTimeout)")
      end
    end

    context "when headway is available" do
      before { stub_request(:get, Blog::Feed::HEADWAY_URL).to_return(body: file_fixture("headway_home.html")) }

      it "provides metadata and posts list" do
        expect_feed_loaded(klass.instance)
      end

      it "caches the fetched HTML" do
        expect { klass.instance }.to change { Rails.cache.fetch(Blog::Feed::CACHE_KEY, nil) }.from(nil)
      end
    end
  end

  context "when the cache is hot" do
    before { Rails.cache.write(Blog::Feed::CACHE_KEY, file_fixture("headway_home.html")) }

    it "does not try to fetch from the internet" do
      klass.instance
      expect(WebMock).not_to have_requested(:any, /.*/)
    end

    it "provides metadata and posts list" do
      expect_feed_loaded(klass.instance)
    end
  end
end
