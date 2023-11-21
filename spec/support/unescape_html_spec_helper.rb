module UnescapeHtmlSpecHelper
  def unescape_html(text)
    CGI.unescapeHTML(text)
  end

  def unescaped_response_body
    unescape_html(response.body)
  end
end
