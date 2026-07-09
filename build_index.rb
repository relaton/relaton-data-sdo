# frozen_string_literal: true

require "yaml"

# Merges the per-org source under orgs/<slug>/ into the single index.yaml the
# `Relaton::Sdo` client consumes. Each org contributes:
#
#   orgs/<slug>/metadata.yaml  -> abbreviation + name/translations
#   orgs/<slug>/logos.yaml     -> logo variants, each with a relative `file:`
#
# The build keys organizations by their (upper-cased) abbreviation and rewrites
# every logo `file:` to its absolute, published `url:` under RAW_BASE. Binaries
# are never inlined — only their URLs — so the published manifest stays small.
module IndexBuilder
  # Base of the raw asset URLs in the published manifest. Matches
  # Relaton::Sdo::Config::DEFAULT_URL's host/branch so the client resolves both
  # the index and the logos from the same place with no configuration.
  RAW_BASE =
    "https://raw.githubusercontent.com/relaton/relaton-data-sdo/main"

  module_function

  # Build the merged manifest as a plain Hash. `root` is the repo root. Raises
  # on a duplicate abbreviation rather than letting one org silently overwrite
  # another in the map.
  def build(root:)
    organizations = org_dirs(root).each_with_object({}) do |dir, acc|
      abbreviation, entry = organization(dir)
      if acc.key?(abbreviation)
        raise "duplicate abbreviation #{abbreviation.inspect} " \
              "(from orgs/#{File.basename(dir)})"
      end

      acc[abbreviation] = entry
    end
    { "organizations" => organizations }
  end

  # Build and write index.yaml at the repo root; returns the path written.
  def write(root:, out: File.join(root, "index.yaml"))
    File.write(out, dump(build(root: root)))
    out
  end

  # Deterministic YAML: a leading `---`, keys in insertion order, no line wrap
  # (long logo URLs must not be folded).
  def dump(data)
    YAML.dump(data, line_width: -1)
  end

  def org_dirs(root)
    Dir[File.join(root, "orgs", "*")].select { |d| File.directory?(d) }.sort
  end

  # One organization: [abbreviation, {name:, logo:}].
  def organization(dir)
    metadata = YAML.safe_load_file(File.join(dir, "metadata.yaml"))
    abbreviation = metadata.fetch("abbreviation").to_s
    slug = File.basename(dir)

    entry = { "name" => metadata["name"], "logo" => logos(dir, slug) }
    [abbreviation.upcase, entry]
  end

  # This org's logo variants with `file:` resolved to an absolute `url:`.
  def logos(dir, slug)
    file = File.join(dir, "logos.yaml")
    return [] unless File.file?(file)

    Array((YAML.safe_load_file(file) || {})["logo"]).map do |logo|
      resolve(logo, slug)
    end
  end

  # Replace the relative `file:` with the published absolute `url:`, keeping the
  # descriptive keys (style/format/size/applicability) in a stable order.
  def resolve(logo, slug)
    resolved = logo.reject { |k, _| k == "file" }
    resolved["url"] = "#{RAW_BASE}/orgs/#{slug}/logos/#{logo['file']}"
    ordered(resolved)
  end

  KEY_ORDER = %w[style format size url applicability].freeze

  def ordered(logo)
    logo.sort_by { |k, _| KEY_ORDER.index(k) || KEY_ORDER.size }.to_h
  end
end

IndexBuilder.write(root: __dir__) if __FILE__ == $PROGRAM_NAME
