class BlogPost < ApplicationRecord
  HEADWAY_URL = "https://headwayapp.co/rdv-service-public-changelog".freeze

  def self.new_content_for_agent?(agent)
    return false unless latest_post_at

    # Ce return permet de considérer que les posts Headway postés jusqu'ici ont déjà été lus.
    # TODO: Supprimer cette ligne lorsque l'on poste sur Headway la prochaine fois.
    return false if latest_post_at < Time.zone.parse("2025-10-15")

    return true if agent.blog_read_at.nil?

    latest_post_at > agent.blog_read_at
  end

  def self.latest_post_at
    maximum(:published_at)
  end

  def self.refresh_from_posts(posts)
    transaction do
      delete_all
      posts.each do |post_attrs|
        create!(post_attrs)
      end
    end
  end
end
