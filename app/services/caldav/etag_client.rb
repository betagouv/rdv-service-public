# Calendav ne permet ni de lister les etags des événements d'un calendrier, ni de récupérer
# un lot d'événements à partir de leurs URLs (report calendar-multiget, RFC 4791 §7.9).
# Ces deux requêtes permettent une synchro incrémentale avec les serveurs qui ne supportent
# pas le sync token (Zimbra notamment) : on ne télécharge que les événements nouveaux ou modifiés.
class Caldav::EtagClient
  MULTIGET_BATCH_SIZE = 100

  def initialize(credentials)
    @endpoint = Calendav::Endpoint.new(credentials)
  end

  # Retourne un Hash { url de l'événement => etag }
  def etags(calendar_url)
    request = Nokogiri::XML::Builder.new do |xml|
      xml["dav"].propfind(Calendav::NAMESPACES) do
        xml["dav"].prop do
          xml["dav"].resourcetype
          xml["dav"].getetag
        end
      end
    end

    etags = @endpoint.propfind(request.to_xml, url: calendar_url, depth: 1)
      .reject { |node| node.xpath(".//dav:resourcetype/dav:collection").any? }
      .map { |node| [Calendav::ContextualURL.call(calendar_url, node.xpath("./dav:href").text), node.xpath(".//dav:getetag").text] }

    warn_about_duplicate_urls(etags)

    etags.to_h
  end

  def events(calendar_url, event_urls)
    event_urls.each_slice(MULTIGET_BATCH_SIZE).flat_map do |batch|
      @endpoint.report(multiget_request(batch).to_xml, url: calendar_url, depth: 1)
        .reject { |node| node.xpath(".//caldav:calendar-data").text.empty? }
        .map { |node| Calendav::Event.from_xml(calendar_url, node) }
    end
  end

  private

  # Certains serveurs (EGroupware) renvoient plusieurs événements sous le même href, et le Hash ci-dessus les écrase.
  # On se contente de prévenir Sentry pour savoir si ce cas arrive aussi dans ce mode de synchro.
  def warn_about_duplicate_urls(etags)
    urls = etags.map(&:first)
    return if urls.uniq.size == urls.size

    Sentry.capture_message("Serveur CalDAV incompatible : URLs en doublon dans la liste des etags", extra: { duplicate_count: urls.size - urls.uniq.size })
  end

  def multiget_request(event_urls)
    Nokogiri::XML::Builder.new do |xml|
      xml["caldav"].public_send(:"calendar-multiget", Calendav::NAMESPACES) do
        xml["dav"].prop do
          xml["dav"].getetag
          xml["caldav"].public_send(:"calendar-data")
        end
        event_urls.each { |url| xml["dav"].href(URI(url).path) }
      end
    end
  end
end
