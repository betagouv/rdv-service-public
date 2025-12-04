require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "successfully connects when agent provides Devise session in cookie" do
    agent = create(:agent)
    valid_session_cookie = {
      "session_id" => "des_chiffres_et_des_lettres",
      "warden.user.agent.key" => [[agent.id], "des_chiffres_et_des_lettres"],
      "warden.user.agent.session" => { "last_request_at" => 2.minutes.ago.to_i },
      "_csrf_token" => "des_chiffres_et_des_lettres",
    }
    cookies.encrypted["_rdv_sp_session"] = { value: valid_session_cookie }
    connect "/cable"
    expect(connection.current_agent).to eq(agent)
  end

  it "rejects connection when no cookie is provided" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "logs to Redis if session is there but without agent id" do
    weird_session_cookie = { "session_id" => "des_chiffres_et_des_lettres" }
    cookies.encrypted["_rdv_sp_session"] = { value: weird_session_cookie }
    expect { connect "/cable" }.to have_rejected_connection
    expect(JSON.parse(Redis.with_connection { _1.rpop "action_cable_connection_debug" })).to eq(weird_session_cookie)
  end
end
