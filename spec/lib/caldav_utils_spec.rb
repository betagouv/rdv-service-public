RSpec.describe CaldavUtils do
  describe ".fully_writable?" do
    def calendar_with(privileges)
      instance_double(Calendav::Calendar, current_user_privilege_set: privileges)
    end

    it "is false when only read privileges are granted" do
      expect(described_class.fully_writable?(calendar_with(%w[read read-current-user-privilege-set]))).to be false
    end

    it "is false for read-free-busy only" do
      expect(described_class.fully_writable?(calendar_with(%w[read-free-busy]))).to be false
    end

    %w[write-properties write-content bind unbind].each do |privilege|
      it "is false when only #{privilege} is granted (partial write access)" do
        expect(described_class.fully_writable?(calendar_with(["read", privilege]))).to be false
      end
    end

    %w[all write].each do |privilege|
      it "is true when #{privilege} is granted" do
        expect(described_class.fully_writable?(calendar_with(["read", privilege]))).to be true
      end
    end

    it "is true when all four write component privileges are granted without the aggregate" do
      privileges = %w[read write-properties write-content bind unbind]
      expect(described_class.fully_writable?(calendar_with(privileges))).to be true
    end

    it "is false when three of the four write component privileges are granted" do
      privileges = %w[read write-properties write-content bind]
      expect(described_class.fully_writable?(calendar_with(privileges))).to be false
    end

    it "is false when privileges are unknown (nil)" do
      expect(described_class.fully_writable?(calendar_with(nil))).to be false
    end

    it "is false when privileges are unknown (empty)" do
      expect(described_class.fully_writable?(calendar_with([]))).to be false
    end
  end
end
