module PageSpecHelper
  def expect_page_title(title)
    expect(page).to have_selector("h1.fr-h2", text: title)
  end

  def wait_for_websocket_frame(predicate_block, &wait_block)
    queue = Queue.new
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.on("websocket", lambda { |ws|
        ws.on("framereceived", lambda { |data|
          queue << true if predicate_block.call(data)
        })
      })
    end
    wait_block&.call
    Timeout.timeout(10) { queue.pop }
  end
end
