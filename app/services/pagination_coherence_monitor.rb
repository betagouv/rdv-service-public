class PaginationCoherenceMonitor
  class Error < StandardError; end

  attr_reader :current_page_number, :current_page_items_count, :total_pages, :per_page, :total_items_count

  def initialize(current_page_number:, current_page_items_count:, total_pages:, per_page:, total_items_count:)
    @current_page_number = current_page_number
    @current_page_items_count = current_page_items_count
    @total_pages = total_pages
    @total_items_count = total_items_count
    @per_page = per_page
  end

  # current_page_arel is useful if you run a second query for the current_page only
  def self.from_paginated_arel(paginated_arel:, current_page_arel: nil)
    new(
      current_page_number: paginated_arel.current_page,
      current_page_items_count: current_page_arel.present? ? current_page_arel.count : paginated_arel.count,
      total_pages: paginated_arel.total_pages,
      total_items_count: paginated_arel.total_count,
      per_page: paginated_arel.limit_value
    )
  end

  def call
    warn_if_intermediate_page_is_not_full ||
      warn_if_last_page_should_have_remaining_items
  end

  private

  def warn_if_intermediate_page_is_not_full
    if total_pages > 1 &&
       current_page_number < total_pages &&
       current_page_items_count != per_page
      warn("la page #{current_page_number}/#{total_pages} contient #{current_page_items_count} items au lieu de #{per_page}")
      true
    end
  end

  def warn_if_last_page_should_have_remaining_items
    remainder = total_items_count % per_page
    expected = remainder.zero? && total_items_count.positive? ? per_page : remainder
    if current_page_number == total_pages && current_page_items_count != expected
      warn("la dernière page #{current_page_number} contient #{current_page_items_count} au lieu de #{expected} items")
      true
    end
  end

  def warn(message)
    Sentry.set_context("pagination_data", pagination_data)
    Sentry.capture_exception(Error.new(message), level: :warning)
  end

  def pagination_data
    { current_page_number:, current_page_items_count:, total_pages:, per_page:, total_items_count: }
  end
end
