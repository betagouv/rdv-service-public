# frozen_string_literal: true

describe "using netsize to send an SMS" do
  let(:territory) { create(:territory, sms_provider: "netsize") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:user) { create(:user, phone_number: "+33601020304") }
  let(:rdv) { create(:rdv, organisation: organisation, users: [user]) }

  before do
    stub_netsize_ok
  end

  it "calls netsize API" do
    Users::RdvSms.rdv_created(rdv, rdv.users.first, "t0k3n").deliver_later

    valid_request = lambda do |req|
      body = URI.decode_www_form(req.body).to_h
      expected_body = {
        "campaignName" => "dpt-#{organisation.departement_number} org-#{organisation.id} rdv_sms",
        "destinationAddress" => "+33601020304",
        "maxConcatenatedMessages" => "10",
        "originatingAddress" => "RdvSoli",
        "originatorTON" => "1",
      }
      expect(body).to include(expected_body)
    end
    expect(WebMock).to(have_requested(:post, "https://europe.ipx.com/restapi/v1/sms/send").with(&valid_request))
  end

  def expect_error_to_be_logged
    expect(Sentry).to receive(:add_breadcrumb).twice

    expect do
      expect do
        Users::RdvSms.rdv_created(rdv, rdv.users.first, "t0k3n").deliver_later
      end.to raise_error(SmsSender::SmsSenderFailure)
    end.to change(Receipt, :count).by(1)
  end

  it "warns Sentry when netsize has a timeout" do
    stub_request(:post, "https://europe.ipx.com/restapi/v1/sms/send")
      .to_timeout

    expect_error_to_be_logged
  end

  it "warns Sentry when netsize responds with an HTTP error" do
    stub_request(:post, "https://europe.ipx.com/restapi/v1/sms/send")
      .to_return(status: 500, body: "", headers: {})

    expect_error_to_be_logged
  end

  it "warns Sentry when netsize responds with a business error" do
    stubbed_body = {
      "responseCode" => 100,
      "responseMessage" => "“Invalid destination address”",
    }.to_json

    stub_request(:post, "https://europe.ipx.com/restapi/v1/sms/send")
      .to_return(status: 200, body: stubbed_body, headers: {})

    expect_error_to_be_logged
  end
end
