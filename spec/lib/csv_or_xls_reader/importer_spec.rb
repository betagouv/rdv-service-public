describe CsvOrXlsReader::Importer do
  subject { described_class.new(form_file).rows }

  let(:form_file) { double }
  let(:asset_path) { File.join(File.dirname(__FILE__), "../../assets/#{filename}") }

  before do
    allow(form_file).to receive(:original_filename).and_return(filename)
    allow(form_file).to receive(:tempfile).and_return(asset_path)
  end

  context "csv" do
    let(:filename) { "zones_1.csv" }

    it "works" do
      expect(subject).to eq(
        [
          { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
          { "city_code" => "62110", "city_name" => "ARQUES", "organisation_id" => "arques" },
          { "city_code" => "62007", "city_name" => "ACQ", "organisation_id" => "arras-sud" }
        ]
      )
    end
  end

  context "xls" do
    let(:filename) { "zones_1.xls" }

    it "works" do
      expect(subject).to eq(
        [
          { "city_code" => "62040", "city_name" => "AIRE-SUR-LA-LYS", "organisation_id" => "arques" },
          { "city_code" => "62110", "city_name" => "ARQUES", "organisation_id" => "arques" },
          { "city_code" => "62007", "city_name" => "ACQ", "organisation_id" => "arras-sud" }
        ]
      )
    end
  end
end
