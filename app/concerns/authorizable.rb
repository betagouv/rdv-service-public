module Authorizable
  extend ActiveSupport::Concern

  included do
    [User, Pro].each do |klass|
      define_method("#{klass.name.underscore}?") { is_a?(klass) }
    end
  end
end
