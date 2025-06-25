module ConfigurationHelper
  def needs_configuration(organisation)
    organisation.motifs.active.none? || needs_lieu(organisation)
  end

  def needs_lieu(organisation)
    organisation.motifs.active.where(location_type: :public_office).any? && organisation.lieux.none?
  end

  def territory_navigation(title = nil, previous_links = [])
    content_for(:breadcrumbs) do
      tag.nav class: "configuration-title pb-2 mb-2" do
        tag.ol class: "breadcrumb m-0 p-0" do
          concat(tag.li(class: "breadcrumb-item") do
            link_to admin_territory_path(current_territory) do
              concat(t("admin.territories.nav.configuration_title", territory: current_territory))
            end
          end)
          previous_links.each do |prev_link|
            concat(tag.li(class: "breadcrumb-item") do
              prev_link
            end)
          end

          if title.present?
            concat(tag.li(class: "breadcrumb-item active") do
              title
            end)
          end
        end
      end
    end
  end
end
