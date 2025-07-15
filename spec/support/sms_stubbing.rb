def stub_netsize_ok
  stubbed_body = {
    responseCode: 0,
    messageIds: [123, 456],
  }.to_json

  stub_request(:post, "https://europe.ipx.com/restapi/v1/sms/send")
    .to_return(status: 200, body: stubbed_body, headers: {})
end

def stub_sms_factor_ok
  stubbed_body = {
    status: 1,
    cost: 1,
    credits: 42,
  }.to_json

  stub_request(:get, "https://api.smsfactor.com/send?pushtype=alert&sender=RdvSoli&text=content&to=0612345678")
    .to_return(status: 200, body: stubbed_body, headers: {})
end

def stub_sms_factor_moderation
  stubbed_body = {
    status: -8,
    message: "Votre campagne est en attente de validation",
    cost: 1,
    credits: 42,
  }.to_json

  stub_request(:get, "https://api.smsfactor.com/send?pushtype=alert&sender=RdvSoli&text=content&to=0612345678")
    .to_return(status: 200, body: stubbed_body, headers: {})
end

def expect_sms_enqueued(args)
  expect(SmsJob).to have_been_enqueued.with(hash_including(args))
end
