class BlogPost < ApplicationRecord
  # Balises et attributs conservés à l'affichage du HTML renvoyé par docs.numerique.gouv.fr
  CONTENT_HTML_ALLOWED_TAGS = %w[
    p br strong b em i u s span
    h2 h3 h4 ul ol li blockquote aside code pre hr
    a img figure figcaption
  ].freeze
  CONTENT_HTML_ALLOWED_ATTRIBUTES = %w[href target rel title src alt width role aria-hidden].freeze

  def self.new_content_for_agent?(agent)
    return false unless latest_post_at
    return true if agent.blog_read_at.nil?

    latest_post_at > agent.blog_read_at
  end

  def self.latest_post_at
    maximum(:published_at)
  end

  def self.refresh_from_posts(posts)
    transaction do
      delete_all
      posts.each(&:save!)
    end
  end
end
