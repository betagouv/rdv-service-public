module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |msg| tag.li(msg) }.join
    tag.div(class: "alert alert-danger alert-block devise-bs") do
      tag.button(type: "button", class: "close", data: { dismiss: "alert" }) do
        "&times;"
      end
      tag.ul(class: "mb-0") do
        messages
      end
    end
  end
end
