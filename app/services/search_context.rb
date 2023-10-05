# frozen_string_literal: true

class SearchContext
  def initialize(user:, query_params: {})
    @user = user
    @query_params = query_params
  end
end
