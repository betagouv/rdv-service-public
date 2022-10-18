# frozen_string_literal: true

def stub_netsize_ok
  stubbed_body = {
    responseCode: 0,
    messageIds: [123, 456],
  }.to_json

  stub_request(:post, "https://europe.ipx.com/restapi/v1/sms/send")
    .to_return(status: 200, body: stubbed_body, headers: {})
end

def expect_sms_enqueued(args)
  expect(SmsJob).to have_been_enqueued.with(hash_including(args))
end
