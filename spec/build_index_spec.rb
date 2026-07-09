# frozen_string_literal: true

# Exercises build_index.rb: merging orgs/* into the single manifest the client
# consumes, keyed by upper-cased abbreviation, with each logo `file:` rewritten
# to its absolute published `url:`.
RSpec.describe IndexBuilder do
  let(:built) { described_class.build(root: ROOT) }
  let(:orgs) { built["organizations"] }

  it "produces an organizations map" do
    expect(built).to have_key("organizations")
    expect(orgs).to be_a(Hash)
    expect(orgs).not_to be_empty
  end

  it "keys every organization by its upper-cased abbreviation" do
    orgs.each_key do |key|
      expect(key).to eq(key.upcase)
    end
  end

  it "carries names through from metadata, keyed by the upper-cased abbreviation" do
    org_dirs.each do |dir|
      meta = YAML.safe_load_file(File.join(dir, "metadata.yaml"))
      entry = orgs.fetch(meta["abbreviation"].upcase)
      expect(entry["name"]).to eq(meta["name"])
    end
  end

  it "rewrites every logo file to an absolute raw URL that resolves to a real asset" do
    orgs.each do |abbr, entry|
      Array(entry["logo"]).each do |logo|
        expect(logo["url"]).to start_with(described_class::RAW_BASE)
        expect(logo).not_to have_key("file")

        rel = logo["url"].delete_prefix("#{described_class::RAW_BASE}/")
        expect(File.file?(File.join(ROOT, rel))).to be(true),
                                                    "#{abbr} logo url does not resolve: #{logo['url']}"
      end
    end
  end

  it "passes applicability through verbatim when present" do
    with_applicability = orgs.values.flat_map { |e| Array(e["logo"]) }
                             .select { |l| l.key?("applicability") }
    expect(with_applicability).not_to be_empty, "expected at least one seeded applicability"
    with_applicability.each do |logo|
      expect(logo["applicability"]).to be_a(String)
    end
  end

  it "always emits an array for the logo list (never nil), even when empty" do
    orgs.each_value do |entry|
      expect(entry["logo"]).to be_a(Array)
    end
  end
end
