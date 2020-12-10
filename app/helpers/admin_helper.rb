module AdminHelper
  def display_value_or_na_placeholder(value)
    content_tag(
      :span,
      value.presence || "N/A",
      class: value.blank? ? "text-muted" : ""
    )
  end
end
