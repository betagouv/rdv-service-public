module DomainDetection
  include Memery
  extend ActiveSupport::Concern

  included do
    helper_method :current_domain
  end

  memoize def current_domain
    Domain.find_matching(URI.parse(request.url).host)
  end
end
