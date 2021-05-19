# frozen_string_literal: true

class BaseService
  def self.perform_with(*args, **kwargs)
    new(*args, **kwargs).perform
  end
end
