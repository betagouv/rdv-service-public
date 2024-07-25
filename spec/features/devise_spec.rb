RSpec.describe "Race condition on devise confirmable" do
  around do |example|
    # We'll need to record the devise notifications we send from other processes, so we write them in a tempfile
    $deliveries = Tempfile.new("deliveries")
    example.run
    $deliveries.unlink
  end

  # The js: true option is to make sure that DatabaseCleaner is using truncation
  it "doesn't allow confirming an email address without having access to it", js: true do
    user = create(:user)

    user.update(email: "hacker@hacker.com") # to set the unconfirmed_email

    class User
      # We only keep the emails sent to the attacker
      def send_devise_notification(notification, token, *args)
        if notification == :confirmation_instructions && args.first[:to] == "hacker@hacker.com"
          $deliveries.write(token)
        end
      end
    end

    # We're going to simulate two web servers processing concurrent requests to update the user's email by forking this process
    #
    # Here's the order in which we'll do the operations
    # - load reloaded_user from the db
    # - load other_reloaded_user from the db
    # - commit the transaction to write other_reloaded_user to the db
    # - commit the transaction to write reloaded_user to the db
    # - This second commit will send an email to hacker@hacker.com with the token to confirm official@legit.com
    #
    #
    # To understand the order of operations better, uncomment the following line
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    fast_pid = fork do
      User.before_commit -> { sleep 0.2 } # We also want the transaction here to be a bit slow to make sure we can load the user in both processes before updating
      other_reloaded_user = User.find(user.id)

      other_reloaded_user.update(email: "official@legit.com") # changes the unconfirmed_email and token. This transaction will commit first
    end

    slow_pid = fork do
      User.before_commit -> { sleep 1 } # Makes the transaction slow to commit only in this process. This could be happening just because of network latency with the database connection
      # 1 second might not be reliable enough to always make this test behave properly. Feel free to increase this depending on your setup

      reloaded_user = User.find(user.id)

      reloaded_user.update(email: "hacker@hacker.com") # only generates a new token. This transaction will commit last
    end

    # Uncomment this line as well if you uncommented the one above
    # ActiveRecord::Base.logger = nil

    # Wait for both updates to finish
    Process.wait(fast_pid)
    Process.wait(slow_pid)
    $deliveries.rewind

    token_sent_to_attacker = $deliveries.read

    user = User.find(user.id)

    puts "User has the values #{user.unconfirmed_email} #{user.confirmation_token}"
    puts "The attacker has received the token #{token_sent_to_attacker}"

    confirmed_user = User.confirm_by_token(token_sent_to_attacker) # This happens when the attacker clicks the link in their email

    # If this expectation fails, the attacker managed to change their email to an address they don't control
    expect(confirmed_user&.email).not_to eq "official@legit.com"
  end
end
