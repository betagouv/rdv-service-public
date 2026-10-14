RSpec.describe CalendavSurrogatePairsFix do
  let(:xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:multistatus xmlns:d="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
        <d:response>
          <d:href>/calendars/agent/event.ics</d:href>
          <d:propstat>
            <d:prop>
              <cal:calendar-data>LOCATION:&#55357;&#56525; Mairie &#xD83D;&#xDE97;</cal:calendar-data>
            </d:prop>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end

  it "recombine les paires de substitution UTF-16 pour que Calendav puisse parser la réponse" do
    response = Calendav::Parsers::ResponseXML.call(xml)

    expect(response.first.xpath(".//caldav:calendar-data").text).to eq("LOCATION:📍 Mairie 🚗")
  end

  it "laisse intactes les références de caractères valides et les substituts isolés" do
    expect(described_class.fix("&#128205; &#233; &#55357;")).to eq("&#128205; &#233; &#55357;")
  end

  # Ce correctif surcharge une méthode privée de Calendav : on vérifie via l'API publique de la gem
  # qu'elle passe toujours par Calendav::Parsers::ResponseXML#parse.
  it "s'applique aux réponses reçues par le client Calendav" do
    calendar_url = "https://caldav.example.com/calendars/agent/"
    stub_request(:report, calendar_url).to_return(status: 207, body: xml, headers: { "Content-Type" => "application/xml" })
    client = Calendav::Client.new(
      Calendav::Credentials::Standard.new(host: calendar_url, username: "agent", password: "secret", authentication: :basic_auth)
    )

    expect(client.events.list(calendar_url).first.calendar_data).to eq("LOCATION:📍 Mairie 🚗")
  end
end
