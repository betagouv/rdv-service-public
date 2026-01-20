module DocsNumeriqueChangelog
  BASE_URL = "https://docs.numerique.gouv.fr/api/v1.0".freeze
  PARENT_DOCUMENT_ID = "b0e65135-967f-4816-a4a9-4757d588fa99".freeze

  def self.fetch_and_parse_blog_posts
    Client.instance.fetch_and_parse_children_documents(PARENT_DOCUMENT_ID).map(&:to_blog_post)
  end

  class Client
    include Singleton

    def fetch_and_parse_children_documents(parent_document_id)
      response = connection.get("documents/#{parent_document_id}/children/")
      response.body["results"].map do |child_data|
        content = fetch_content(child_data["id"])
        ChildDoc.new(
          id: child_data["id"],
          raw_title: child_data["title"],
          content:
        )
      end
    end

    private

    def fetch_content(document_id)
      response = connection.get("documents/#{document_id}/content/", content_format: "html")
      response.body.fetch("content")
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.response :json
        f.response :raise_error
      end
    end
  end

  class ChildDoc
    attr_reader :id, :title, :categories, :description, :published_at

    def initialize(id:, raw_title:, content:)
      @id = id
      parse_raw_title(raw_title)
      parse_content(content)
    end

    def to_blog_post
      BlogPost.new(
        title:,
        categories:,
        description:,
        external_url: "https://docs.numerique.gouv.fr/docs/#{id}",
        published_at:
      )
    end

    TITLE_REGEX = %r{
      ^
      (?<title>.*)        # Vos RDV collectifs, maintenant en visio
      \p{Zs}?-\p{Zs}?     # -  (\p{Zs} = Separators: Space - handles non breaking spaces)
      (?<date>[0-9\/]+)   # 15/01/2026
      \p{Zs}?-\p{Zs}?     # -
      (?<category>.*)     # Nouveauté
      \p{Zs}*
      $
    }x

    private

    def parse_raw_title(raw_title)
      res = raw_title.match(TITLE_REGEX)

      if res
        @title = res[:title].strip
        @categories = [res[:category].strip]
        @published_at = Time.zone.strptime(res[:date].strip, "%d/%m/%Y")
      else
        raise TitleFormatError, "la date de publication n'a pas pu être parsée depuis '#{raw_title}'"
      end
    end

    def parse_content(html_content)
      doc = Nokogiri::HTML.fragment(html_content)
      @description = doc.children.map(&:text).join(" ").squish.truncate(500)
    end
  end

  class TitleFormatError < StandardError; end
end
