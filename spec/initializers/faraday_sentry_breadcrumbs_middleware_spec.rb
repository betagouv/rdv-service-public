RSpec.describe FaradaySentryBreadcrumbsMiddleware do
  it "provides info about the request and response" do
    stub_request(:post, "https://example.com/posts")
      .to_return(
        status: 201,
        headers: { "Content-Type": "application/json" },
        body: '{"status": "ok"}'
      )

    connection = Faraday.new("https://example.com") do |builder|
      builder.use :sentry_breadcrumbs
    end

    connection.post("/posts", { title: "Mon article de blog" }.to_json, { Authorization: "Token token=abcd1234efgh" })
    Sentry.capture_message("woops")

    request_breadcrumb, response_breadcrumb = sentry_events.last.breadcrumbs.compact

    expect(request_breadcrumb.message).to eq("HTTP request")
    expect(request_breadcrumb.data[:body]).to eq({ title: "Mon article de blog" }.to_json)
    expect(request_breadcrumb.data[:headers]).to eq({ "Authorization" => "Token token=abcd1234efgh", "User-Agent" => "Faraday v2.9.0" })
    expect(request_breadcrumb.data[:method]).to eq(:post)
    expect(request_breadcrumb.data[:url].to_s).to eq("https://example.com/posts")

    expect(response_breadcrumb.message).to eq("HTTP response")
    expect(response_breadcrumb.data[:status]).to eq(201)
    expect(response_breadcrumb.data[:headers]).to eq({ "content-type" => "application/json" })
    expect(response_breadcrumb.data[:body]).to eq('{"status": "ok"}')
  end

  context "when used after the :raise_error middleware" do
    it "still works" do
      stub_request(:post, "https://example.com/posts")
        .to_return(status: 500)

      connection = Faraday.new("https://example.com") do |builder|
        builder.response :raise_error # raise an error on 4xx and 5xx responses
        builder.use :sentry_breadcrumbs
      end

      expect { connection.post("/posts") }.to raise_error(Faraday::ServerError)
      Sentry.capture_message("woops")

      request_breadcrumb, response_breadcrumb = sentry_events.last.breadcrumbs.compact
      expect(request_breadcrumb.message).to eq("HTTP request")

      expect(response_breadcrumb.message).to eq("HTTP response")
      expect(response_breadcrumb.data[:status]).to eq(500)
    end
  end

  context "when the request times out" do
    it "adds a breadcrumb" do
      stub_request(:post, "https://example.com/posts")
        .to_timeout

      connection = Faraday.new("https://example.com") do |builder|
        builder.use :sentry_breadcrumbs
      end

      expect { connection.post("/posts") }.to raise_error(Faraday::ConnectionFailed)
      Sentry.capture_message("woops")
      _request_breadcrumb, timeout_breadcrumb = sentry_events.last.breadcrumbs.compact

      expect(timeout_breadcrumb.data).to eq(exception_message: "execution expired")
    end
  end

  describe "scrub_request_body option" do
    it "scrubs the request body when set to true" do
      stub_request(:post, "https://example.com/posts")

      connection = Faraday.new("https://example.com") do |builder|
        builder.use :sentry_breadcrumbs, scrub_request_body: true
      end

      connection.post("/posts", { title: "Mon article de blog" }.to_json)
      Sentry.capture_message("woops")

      request_breadcrumb, _response_breadcrumb = sentry_events.last.breadcrumbs.compact

      expect(request_breadcrumb.message).to eq("HTTP request")
      expect(request_breadcrumb.data[:body]).to eq("[SCRUBBED]")
    end
  end
end
