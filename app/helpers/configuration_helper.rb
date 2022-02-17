# frozen_string_literal: true

module ConfigurationHelper
  def territory_navigation(title = nil, previous_links = [])
    tag.nav class: "border-bottom configuration-title border-bottom pb-2 configuration-title mb-2" do
      tag.ol class: "breadcrumb m-0 p-0" do
        concat(tag.li(class: "breadcrumb-item") do
          link_to admin_territory_path(current_territory) do
            concat(tag.i(class: "fa fa-cogs"))
            concat(" ")
            concat(t("admin.territories.nav.configuration_title"))
          end
        end)
        if previous_links.any?
          previous_links.each do |prev_link|
            concat(tag.li(class: "breadcrumb-item") do
              prev_link
            end)
          end
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
