module CreneauxHelper
  def display_creneau(creneau, link)
    link_to link, class: "btn btn-light mr-1 mb-1 w-100" do
      content_tag(:span, l(creneau.starts_at, format: "%H:%M")) +
        tag(:br) +
        content_tag(:small, creneau.agent_name)
    end
  end
end
