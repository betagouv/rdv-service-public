# cf https://mattpruitt.com/post/skip-callbacks/
module SkipCallbacks
  def run_callbacks(_kind, *args, &_block)
    yield(*args) if block_given?
  end
end
