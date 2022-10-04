# frozen_string_literal: true

module DeviseRequestSpecHelpers
  include Warden::Test::Helpers

  def sign_in(resource_or_scope, resource = nil)
    resource ||= resource_or_scope
    login_as(resource, scope: Devise::Mapping.find_scope!(resource_or_scope))
  end
end
