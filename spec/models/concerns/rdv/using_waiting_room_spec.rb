# frozen_string_literal: true

RSpec.describe Rdv::UsingWaitingRoom do
  it "Reset all `user_in_waiting_room` keys in redis" do
    list_rdv = create_list(:rdv, 3)

    # On garde une trace des RDV
    # pour signaler que les usagers
    # sont en salle d'attente
    list_rdv.map(&:set_user_in_waiting_room!)
    expect(Rdv.all.map(&:user_in_waiting_room?)).to eq([true, true, true])

    Rdv.reset_user_in_waiting_room!

    expect(Rdv.all.map(&:user_in_waiting_room?)).to eq([false, false, false])
  end
end
