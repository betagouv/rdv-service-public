module PageSpecHelper
  def expect_page_title(title)
    expect(page).to have_selector("h1.fr-h2", text: title)
  end

  def wait_for_action_cable_subscription_to(channel_name, &wait_block)
    predicate_block = lambda do |web_socket_frame|
      web_socket_frame.include?('"type":"confirm_subscription"') && web_socket_frame.include?(channel_name)
    end
    wait_for_websocket_frame(predicate_block, &wait_block)
  end

  def wait_for_websocket_frame(predicate_block, &wait_block)
    queue = Queue.new
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.on("websocket", lambda { |ws|
        ws.on("framereceived", lambda { |web_socket_frame|
          queue << true if predicate_block.call(web_socket_frame)
        })
      })
    end
    wait_block.call
    Timeout.timeout(5) { queue.pop }
  end
end
