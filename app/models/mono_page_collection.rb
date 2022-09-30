# frozen_string_literal: true

#
# This is meant to behave live a pseudo-paginated collection
# of objects, just like Kaminari::PaginatableArray does, but simpler
# and with the ability to declare the class of the collection.
#
class MonoPageCollection < Array
  def initialize(collection, collection_class)
    @collection_class = collection_class
    super(collection)
  end

  def klass
    @collection_class
  end

  def page(*)
    self
  end

  def per(*)
    self
  end

  def current_page
    1
  end

  def total_pages
    1
  end

  def total_count
    size
  end

  def prev_page
    nil
  end

  def next_page
    nil
  end
end
