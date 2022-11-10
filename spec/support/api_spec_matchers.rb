# frozen_string_literal: true

RSpec::Matchers.define :be_paginated do |pagination|
  match do
    pagination.with_indifferent_access == parsed_response_body[:meta]
  end
end
