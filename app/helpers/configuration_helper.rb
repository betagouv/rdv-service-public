module ConfigurationHelper
  def needs_configuration(organisation)
    organisation.motifs.active.none? || needs_lieu(organisation)
  end

  def needs_lieu(organisation)
    organisation.motifs.active.where(location_type: :public_office).any? && organisation.lieux.enabled.none?
  end

  def territory_navigation(title = nil, previous_links = [])
    dsfr_breadcrumbs do |b|
      b.with_breadcrumb label: t("admin.territories.nav.configuration_title", territory: current_territory.name_for_agent), href: admin_territory_path(current_territory)
      previous_links.each do |label, href|
        b.with_breadcrumb label:, href:
      end
      if title.present?
        b.with_breadcrumb label: title
      end
    end
  end
end
