# frozen_string_literal: true

RSpec::Matchers.define :be_paginated do |pagination|
  match do
    pagination.with_indifferent_access == parsed_response_body[:meta]
  end
end

RSpec::Matchers.define :json_payload_with_meta do |key, value|
  match do |actual|
    content = ActiveSupport::JSON.decode(actual)
    content["meta"][key] == value
  end
end
