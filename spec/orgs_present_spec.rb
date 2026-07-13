# frozen_string_literal: true

# Locks in the specific publishers seeded for relaton/relaton#40 (single source of
# truth for "SDO abbreviation -> organisation name"). The generic schema/build
# specs iterate whatever orgs exist; this one asserts that *these* abbreviations
# are actually present in the built manifest, each with an English default name,
# and pins the two translations the issue calls out by example (ITU ru, MLIT ja).
RSpec.describe "seeded SDO publishers" do
  let(:orgs) { IndexBuilder.build(root: ROOT)["organizations"] }

  # Abbreviation => the English default (unlanguaged) name it must carry.
  EXPECTED = {
    "ITU" => "International Telecommunication Union",
    "ITU-R" => "ITU Radiocommunication Sector",
    "ITU-T" => "ITU Telecommunication Standardization Sector",
    "MLIT" => "Ministry of Land, Infrastructure, Transport and Tourism",
    "IETF" => "Internet Engineering Task Force",
    "W3C" => "World Wide Web Consortium",
    "CEN" => "European Committee for Standardization",
    "CENELEC" => "European Committee for Electrotechnical Standardization",
    "ETSI" => "European Telecommunications Standards Institute",
    "JIS" => "Japanese Industrial Standards",
    "OASIS" => "Organization for the Advancement of Structured Information Standards",
    "ECMA" => "Ecma International",
    "CALCONNECT" => "The Calendaring and Scheduling Consortium",
    "CCSDS" => "Consultative Committee for Space Data Systems",
    "CIE" => "International Commission on Illumination",
    "BIPM" => "International Bureau of Weights and Measures",
    "CGPM" => "General Conference on Weights and Measures",
    "3GPP" => "3rd Generation Partnership Project"
  }.freeze

  EXPECTED.each do |abbr, default_name|
    it "includes #{abbr} with its English default name" do
      entry = orgs[abbr]
      expect(entry).not_to be_nil, "#{abbr} missing from the built manifest"

      names = Array(entry["name"])
      default = names.find { |n| !n.is_a?(Hash) || n["language"].to_s.empty? }
      content = default.is_a?(Hash) ? default["content"] : default
      expect(content).to eq(default_name)
    end
  end

  # The issue's own worked examples must resolve to the exact translations.
  it "resolves the ITU Russian name (issue example)" do
    ru = Array(orgs.fetch("ITU")["name"]).find { |n| n.is_a?(Hash) && n["language"] == "ru" }
    expect(ru&.fetch("content")).to eq("Международный союз электросвязи")
  end

  it "resolves the MLIT Japanese name (issue example)" do
    ja = Array(orgs.fetch("MLIT")["name"]).find { |n| n.is_a?(Hash) && n["language"] == "ja" }
    expect(ja&.fetch("content")).to eq("国土交通省")
  end
end
