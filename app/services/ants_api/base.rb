module AntsApi
  class ApiRequestError < StandardError; end

  class Base
    def headers
      {
        "Accept" => "application/json",
        "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
      }
    end
  end
end
