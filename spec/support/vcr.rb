require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/support/vcr_cassettes"
  config.hook_into :webmock

  config.ignore_request do |request|
    URI(request.uri).host.ends_with?("localhost")
  end

  config.before_record do |interaction|
    interaction.request.headers["Authorization"] = "[Filtered in vcr.rb -> before_record]"
    interaction.response.headers["Set-Cookie"] = "[Filtered in vcr.rb -> before_record]"
  end

  # Ce block formate les réponses XML afin d'améliorer la lisibilité de la cassette
  config.before_record do |interaction|
    content_type = interaction.response.headers["Content-Type"]&.first
    next unless content_type&.include?("xml")

    doc = Nokogiri::XML(interaction.response.body, &:noblanks)
    doc.encoding = "UTF-8"
    interaction.response.body = doc.to_xml(indent: 2, save_with: Nokogiri::XML::Node::SaveOptions::FORMAT)
  rescue Nokogiri::XML::SyntaxError
    # If XML is malformed, leave it untouched
  end
end
