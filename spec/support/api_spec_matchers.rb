# frozen_string_literal: true

RSpec::Matchers.define :be_paginated do |pagination|
  match do |response|
    pagination == {
      current_page: response.headers["X-RDV-Solidarites-Current-Page"],
      next_page: response.headers["X-RDV-Solidarites-Next-Page"],
      prev_page: response.headers["X-RDV-Solidarites-Prev-Page"],
      total_count: response.headers["X-RDV-Solidarites-Total-Count"],
      total_pages: response.headers["X-RDV-Solidarites-Total-Pages"],
    }
  end
end
