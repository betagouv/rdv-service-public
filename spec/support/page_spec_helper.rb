module PageSpecHelper
  def expect_page_title(title)
    expect(page).to have_selector("h1.fr-h2", text: title)
  end
end
