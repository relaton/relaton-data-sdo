# frozen_string_literal: true

# Validates the per-org SOURCE files (orgs/<slug>/metadata.yaml + logos.yaml)
# and that every referenced logo binary actually exists on disk. This is what
# keeps the source honest before build_index.rb merges it.
RSpec.describe "org source files" do
  it "has at least one organization" do
    expect(org_dirs).not_to be_empty
  end

  it "gives every organization a unique abbreviation" do
    abbrevs = org_dirs.map do |dir|
      YAML.safe_load_file(File.join(dir, "metadata.yaml"))["abbreviation"]
    end
    dupes = abbrevs.tally.select { |_, count| count > 1 }.keys
    expect(dupes).to be_empty, "duplicate abbreviations: #{dupes.join(', ')}"
  end

  org_dirs.each do |dir|
    slug = File.basename(dir)

    context slug do
      let(:metadata) { YAML.safe_load_file(File.join(dir, "metadata.yaml")) }
      let(:logos_file) { File.join(dir, "logos.yaml") }
      let(:logos) { YAML.safe_load_file(logos_file) }

      it "has a metadata.yaml" do
        expect(File.file?(File.join(dir, "metadata.yaml"))).to be true
      end

      it "declares a non-empty abbreviation" do
        expect(metadata["abbreviation"]).to be_a(String)
        expect(metadata["abbreviation"].strip).not_to be_empty
      end

      it "uses an upper-case abbreviation" do
        expect(metadata["abbreviation"]).to eq(metadata["abbreviation"].upcase)
      end

      it "declares at least one name with content" do
        names = Array(metadata["name"])
        expect(names).not_to be_empty
        names.each do |n|
          content = n.is_a?(Hash) ? n["content"] : n
          expect(content.to_s.strip).not_to be_empty
        end
      end

      it "has exactly one default (unlanguaged) name" do
        names = Array(metadata["name"])
        defaults = names.select { |n| !n.is_a?(Hash) || n["language"].to_s.empty? }
        expect(defaults.size).to eq(1)
      end

      it "has a logos.yaml with a logo list" do
        expect(File.file?(logos_file)).to be true
        expect(logos["logo"]).to be_a(Array)
      end

      it "gives every logo a style, format and existing file" do
        Array(logos["logo"]).each do |logo|
          expect(logo["style"].to_s.strip).not_to be_empty, "logo missing style"
          expect(logo["format"].to_s.strip).not_to be_empty, "logo missing format"
          expect(logo["file"].to_s.strip).not_to be_empty, "logo missing file"

          path = File.join(dir, "logos", logo["file"])
          expect(File.file?(path)).to be(true), "missing asset #{path}"
          expect(File.size(path)).to be > 0
          expect(File.extname(path).delete(".")).to eq(logo["format"])
        end
      end
    end
  end
end
