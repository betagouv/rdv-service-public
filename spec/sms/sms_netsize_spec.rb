# frozen_string_literal: true

describe "using netsize to send an SMS" do
  before do
    stub_netsize_ok
  end

  it "calls netsize API" do
    territory = create(:territory, sms_provider: "netsize")
    organisation = create(:organisation, territory: territory)
    user = create(:user, phone_number: "+33601020304")
    rdv = create(:rdv, organisation: organisation, users: [user])

    Users::RdvSms.rdv_created(rdv, rdv.users.first, "t0k3n").deliver_later

    valid_request = lambda do |req|
      body = URI.decode_www_form(req.body).to_h
      expected_body = {
        "campaignName" => "dpt-1 org-1 rdv_sms",
        "destinationAddress" => "+33601020304",
        "maxConcatenatedMessages" => "10",
        "originatingAddress" => "RdvSoli",
        "originatorTON" => "1",
      }
      expect(body).to include(expected_body)
    end
    expect(WebMock).to(have_requested(:post, "https://europe.ipx.com/restapi/v1/sms/send").with(&valid_request))
  end
end
