describe UserNote, type: :model do
  it "have a valid factory" do
    expect(build(:user_note)).to be_valid
  end

  it "can not exist without agent" do
    # this is invalid , but some were created like this during the migration
    expect(build(:user_note, agent: nil)).to be_invalid
  end

  it "invalid without text" do
    expect(build(:user_note, text: nil)).to be_invalid
  end
end
