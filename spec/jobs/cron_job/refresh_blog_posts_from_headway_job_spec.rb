RSpec.describe CronJob::RefreshBlogPostsFromHeadwayJob do
  context "when Headway is available" do
    before do
      stub_request(:get, BlogPost::HEADWAY_URL).to_return(body: file_fixture("headway_home.html"))
    end

    it "parses posts and passes them" do
      expect(BlogPost).to receive(:refresh_from_posts).with(satisfy do |post_hashes|
        expect(post_hashes.pluck(:title)).to contain_exactly("Mots de passe forts obligatoires", "Simplification du formulaire des motifs", "Documentation")
      end)
      described_class.new.perform
    end
  end

  context "when Headway is down" do
    before do
      stub_request(:get, BlogPost::HEADWAY_URL).to_timeout
    end

    it "warns Sentry and retries the job" do
      expect(enqueued_jobs).to be_empty
      expect(sentry_events).to be_empty

      described_class.perform_now

      next_try = enqueued_jobs.last
      expect(next_try[:job]).to eq(described_class)
      expect(next_try["exception_executions"]).to eq({ "[StandardError]" => 1 })
      expect(sentry_events.last.exception.values.first.value).to eq("execution expired (Net::OpenTimeout)")
    end
  end
end
