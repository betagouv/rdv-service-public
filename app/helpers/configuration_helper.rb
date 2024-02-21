module ConfigurationHelper
  def territory_navigation(title = nil, previous_links = [])
    tag.nav class: "configuration-title pb-2 mb-2" do
      tag.ol class: "breadcrumb m-0 p-0" do
        concat(tag.li(class: "breadcrumb-item") do
          link_to root_path do
            concat(current_domain.name)
          end
        end)
        concat(tag.li(class: "breadcrumb-item") do
          link_to admin_territory_path(current_territory) do
            concat(t("admin.territories.nav.configuration_title"))
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
