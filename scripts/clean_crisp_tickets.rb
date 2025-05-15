# rails runner scripts/clean_crisp_tickets.rb

class Cleaner
  WEBSITE_ID = ENV.fetch("CRISP_WEBSITE_ID").freeze

  def run
    total_deleted_count = nil
    total_deleted_count = fetch_paginated_routine(page_number: 1) while total_deleted_count != 0
  end

  def should_delete_conversation?(conversation)
    (
      conversation["meta"]["nickname"] == "anonymous" &&
      conversation["last_message"].starts_with?("20 ")
    ) || conversation["meta"]["nickname"].include?("LmMqtzme")
  end

  def fetch_paginated_routine(page_number:, total_deleted_count: 0)
    conversations_count, deleted_count = fetch_conversations_and_delete(page_number:)
    total_deleted_count += deleted_count
    if conversations_count > 0
      fetch_paginated_routine(page_number: page_number + 1, total_deleted_count:)
    else
      total_deleted_count
    end
  end

  def fetch_conversations_and_delete(page_number:)
    puts "\ngetting page #{page_number}…"
    response = connection.get(
      "/v1/website/#{WEBSITE_ID}/conversations/#{page_number}",
      filter_date_start: (Time.zone.today - 1.day).iso8601
    )
    raise "got #{response.status} from GET" if [200, 206].exclude?(response.status)

    conversations = JSON.parse(response.body)["data"]
    conversations_to_delete = conversations.filter { should_delete_conversation?(_1) }
    puts "found #{conversations.count}, among which #{conversations_to_delete.count} will be deleted…"

    conversations_to_delete.each do |conversation|
      raise unless conversation["session_id"].match?(/^[\da-z\-_]+$/) # prevent injections, brakeman false positive

      puts "deleting conversation #{conversation['session_id']} with #{conversation['meta']['nickname']}"
      res = connection.delete "/v1/website/#{WEBSITE_ID}/conversation/#{conversation['session_id']}"
      puts "delete res : #{JSON.parse(res.body)}"
      raise "got status #{res.status} instead of 200." if res.status != 200
    end
    [conversations.count, conversations_to_delete.count]
  end

  def connection
    @connection ||= Faraday.new(url: "https://api.crisp.chat/") do |faraday|
      faraday.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{ENV.fetch('CRISP_IDENTIFIER')}:#{ENV.fetch('CRISP_KEY')}")}"
      faraday.headers["X-Crisp-Tier"] = "plugin"
      faraday.adapter Faraday.default_adapter
    end
  end
end

Cleaner.new.run if $PROGRAM_NAME == __FILE__
