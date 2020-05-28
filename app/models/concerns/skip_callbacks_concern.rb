# cf https://mattpruitt.com/post/skip-callbacks/
module SkipCallbacksConcern
  extend ActiveSupport::Concern

  def run_callbacks(_kind, *args, &_block)
    yield(*args) if block_given?
  end
end
