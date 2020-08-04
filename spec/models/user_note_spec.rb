describe UserNote, type: :model do
  it "have a valid factory" do
    expect(build(:user_note)).to be_valid
  end

  it "could exist without agent" do
    expect(build(:user_note, agent: nil)).to be_valid
  end

  it "invalid without text" do
    expect(build(:user_note, text: nil)).to be_invalid
  end
end
