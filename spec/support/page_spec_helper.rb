module PageSpecHelper
  def expect_page_title(title)
    expect(page).to have_selector("h1.page-title", text: title)
  end

  def expect_page_with_no_record_text(text)
    expect(page).to have_selector(".card .card-body p.lead", text: text)
  end
end
