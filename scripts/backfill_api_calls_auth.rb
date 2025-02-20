# usage: bundle exec rails runner scripts/backfill_api_calls_auth.rb

ApiCall.where(authentication_type: nil).find_each do |api_call|
  headers = api_call.raw_http.delete("headers")

  if headers["HTTP_AUTHORIZATION"]
    api_call.authentication_type = "OAuth"
  elsif headers["HTTP_ACCESS_TOKEN"] && headers["HTTP_UID"]
    api_call.authentication_type = "DeviseTokenAuth"
  elsif headers["HTTP_X_AGENT_AUTH_SIGNATURE"]
    api_call.authentication_type = "SharedSecret"
  end

  api_call.save
end
