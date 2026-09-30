class BlogPost < ApplicationRecord
  DOCS_DOCUMENT_URL_PREFIX = "https://docs.numerique.gouv.fr/docs/".freeze

  def self.new_content_for_agent?(agent)
    return false unless latest_post_at
    return true if agent.blog_read_at.nil?

    latest_post_at > agent.blog_read_at
  end

  def self.latest_post_at
    maximum(:published_at)
  end

  # Les posts sont supprimés puis recréés à chaque rafraîchissement depuis Docs,
  # leur id change donc à chaque fois. On utilise l'id du document Docs pour avoir des URLs stables.
  def self.find_by_docs_document_id!(docs_document_id)
    find_by!(external_url: "#{DOCS_DOCUMENT_URL_PREFIX}#{docs_document_id}")
  end

  def docs_document_id
    external_url.delete_prefix(DOCS_DOCUMENT_URL_PREFIX)
  end

  def to_param
    docs_document_id
  end

  def self.refresh_from_posts(posts)
    transaction do
      delete_all
      posts.each(&:save!)
    end
  end
end
