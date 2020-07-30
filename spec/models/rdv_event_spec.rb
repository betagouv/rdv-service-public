describe RdvEvent, type: :model do
  let(:rdv) { build(:rdv) }

  it "requires a RDV" do
    expect(RdvEvent.new(event_type: RdvEvent::TYPE_NOTIFICATION_SMS).valid?).to eq false
  end

  it "validates type" do
    expect(RdvEvent.new(rdv: rdv, event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: "reminder").valid?).to eq true
    expect(RdvEvent.new(rdv: rdv, event_type: "whatev", event_name: "reminder").valid?).to eq false
  end
end
