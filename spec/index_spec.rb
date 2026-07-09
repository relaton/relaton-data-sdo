# frozen_string_literal: true

# Guards the committed, published index.yaml: it must exist, stay in sync with a
# fresh build, and match the shape `Relaton::Sdo` parses (organizations map →
# name entries → logo entries). We mirror the client's expectations here rather
# than depend on the unreleased gem.
RSpec.describe "index.yaml" do
  let(:path) { File.join(ROOT, "index.yaml") }
  let(:committed) { YAML.safe_load_file(path) }

  it "is committed" do
    expect(File.file?(path)).to be true
  end

  it "is in sync with a fresh build (run `rake build`)" do
    expect(committed).to eq(IndexBuilder.build(root: ROOT))
  end

  describe "shape the client parses" do
    let(:orgs) { committed["organizations"] }

    it "is a mapping under organizations" do
      expect(committed).to be_a(Hash)
      expect(orgs).to be_a(Hash)
    end

    it "gives each org a name array of strings or {content} hashes" do
      orgs.each_value do |entry|
        names = Array(entry["name"])
        expect(names).not_to be_empty
        names.each do |n|
          if n.is_a?(Hash)
            expect(n["content"]).to be_a(String)
          else
            expect(n).to be_a(String)
          end
        end
      end
    end

    it "gives each logo (if any) a fetchable url and a format" do
      orgs.each_value do |entry|
        Array(entry["logo"]).each do |logo|
          expect(logo["url"]).to match(%r{\Ahttps://})
          expect(logo["format"].to_s).not_to be_empty
        end
      end
    end
  end
end
