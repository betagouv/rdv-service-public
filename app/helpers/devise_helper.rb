module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |msg| tag.li(msg) }.join
    html = <<-HTML
    <div class="alert alert-danger alert-block devise-bs">
      <button type="button" class="close" data-dismiss="alert">&times;</button>
      <ul class='mb-0'>#{messages}</ul>
    </div>
    HTML
    html.html_safe
  end
end
