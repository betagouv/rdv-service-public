module DomainDetection
  extend ActiveSupport::Concern

  included do
    helper_method :current_domain
  end

  def current_domain
    @current_domain ||= Domain.find_matching(URI.parse(request.url).host)
  end
end
