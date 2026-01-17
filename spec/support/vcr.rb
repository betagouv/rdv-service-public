require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock

  config.ignore_request do |request|
    URI(request.uri).host.ends_with?("localhost")
  end
end
