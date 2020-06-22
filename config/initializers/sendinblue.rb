SibApiV3Sdk.configure do |config|
  config.api_key['api-key'] = ENV['SENDINBLUE_SMS_API']
end
