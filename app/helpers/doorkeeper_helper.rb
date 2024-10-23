module DoorkeeperHelper
  # TODO: éviter de dupliquer cette méthode
  def current_domain
    @current_domain ||= Domain.find_matching(URI.parse(request.url).host)
  end

  def in_oauth_flow?
    controller_name == "authorizations"
  end
end
