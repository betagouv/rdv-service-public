namespace :matomo do
  task :exclude_params do
    # Please run bundle exec rake matomo:exclude_params
    # if you update that list
    params_to_filter = %w[address /.*_name/ affiliation_number /.*latitude.*/ /.*longitude.*/ /.*where.*/ /.*_token/]

    unless ENV['MATOMO_AUTH_TOKEN']
      raise "A MATOMO_AUTH_TOKEN envvar is required to run that script.
        Such token is available at: https://stats.data.gouv.fr/index.php?module=UsersManager&action=userSettings"
    end

    # Production and Demo sites
    id_sites = %w[123 124]
    id_sites.each do |id_site|
      token_auth = ENV['MATOMO_AUTH_TOKEN']
      # https://developer.matomo.org/api-reference/reporting-api
      url = 'https://stats.data.gouv.fr/index.php?method=SitesManager.updateSite&module=API&format=JSON2'
      payload = {
        idSite: id_site,
        token_auth: token_auth,
        excludedQueryParameters: params_to_filter.join(','),
      }
      response = Typhoeus.post(url, body: payload)
      result = JSON.parse(response.body)

      raise result['message'] unless result['result'] == 'success'
    end
  end
end
