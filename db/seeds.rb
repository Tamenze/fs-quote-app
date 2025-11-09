# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require "yaml"
require "set"

NUM_USERS        = 5
QUOTES_MADE_PER_USER  = 6
TAGS_MADE_PER_USER    = 6
TAGS_ATTACHED_PER_QUOTE = 3
TAGS_TOTAL_NEEDED = NUM_USERS * TAGS_MADE_PER_USER
PASSWORD_DEFAULT = ENV.fetch("SEED_USER_PASSWORD", "changeme123") # fallback for missing Env value
SEEDLETS_DIR = Rails.root.join("db", "seedlets")


# -----------------------------
# Helpers
# -----------------------------
def load_yaml_hash_list!(relative_path, key:)
  full = SEEDLETS_DIR.join(relative_path)
  raise "[seeds] Missing file: #{full}" unless File.exist?(full)
  data = YAML.safe_load_file(full) || {}
  list = data[key]
  raise "[seeds] Missing key '#{key}' in #{full}" if list.nil?
  list
end

def load_yaml_string_list!(relative_path, key:)
  list = load_yaml_hash_list!(relative_path, key: key)
  list = list.filter_map do |s|
    t = s.to_s.strip
    t unless t.blank?
  end
end

# -----------------------------
# Load seed data
# -----------------------------
quotes = load_yaml_hash_list!("quotes.yml", key: "quotes")
needed_quotes = NUM_USERS * QUOTES_MADE_PER_USER 
raise "[seeds] Need at least #{needed_quotes} quotes, got #{quotes.size}." if quotes.size < needed_quotes

raw_tag_names = load_yaml_string_list!("tags.yml", key: "tags")

# -----------------------------
# Optional reset (adapter-agnostic)
# -----------------------------
if ENV["SEED_RESET"] == "1"
  puts "[seeds] SEED_RESET=1 -> clearing tables with delete_all..."
  ActiveRecord::Base.connection.execute("DELETE FROM quotes_tags") # join table (no model)
  Quote.delete_all
  Tag.delete_all
  User.delete_all
end


ActiveRecord::Base.transaction do
  # -----------------------------
  # Users
  # -----------------------------
  puts "[seeds] Creating users..."
  users = (1..NUM_USERS).map do |i|
    email = "user#{i}@example.com"
    User.find_or_create_by!(email: email) do |u|
      u.username = "user#{i}"
      u.password = PASSWORD_DEFAULT
    end
  end

  # -----------------------------
  # Tags (case-insensitive unique, using Tag.normalize_name)
  # -----------------------------
  puts "[seeds] Creating tags (normalized, no numeric suffixes)..."

  # Choose TAGS_TOTAL_NEEDED unique normalized names from YAML
  chosen_norms = []
  # Set of already-present normalized names (DB stores normalized via callback)
  seen_norm = Set.new(Tag.pluck(Arel.sql("lower(name)")))
  raw_tag_names.each do |raw|
    norm = Tag.normalize_name(raw).downcase
    next if norm.blank? || seen_norm.include?(norm) || chosen_norms.include?(norm)
    chosen_norms << norm
    seen_norm << norm
    break if chosen_norms.size >= TAGS_TOTAL_NEEDED
  end

  if chosen_norms.size < TAGS_TOTAL_NEEDED
    raise "[seeds] Not enough unique tag names after normalization. "\
          "Needed #{TAGS_TOTAL_NEEDED}, got #{chosen_norms.size}."
  end

  # Create tags and attribute them evenly to creators
  created_tags = []
  users.each_with_index do |user, idx|
    slice = chosen_norms.slice(idx * TAGS_MADE_PER_USER, TAGS_MADE_PER_USER) || []
    slice.each do |norm_name|
      # Use normalized name in lookup/creation so find_or_create_by aligns with model callback
      created_tags << Tag.find_or_create_by!(name: norm_name) { |t| t.creator = user }
    end
  end

  # store Tags for easy usage (+ perf.) in quote assignment step
  all_tags = Tag.all.to_a

  # -----------------------------
  # Quotes (body-unique, assign exactly 3 random tags each)
  # -----------------------------
  puts "[seeds] Creating quotes and linking 3 random tags each..."
  offset = 0
  users.each do |user|
    my = quotes.slice(offset, QUOTES_MADE_PER_USER ) || []
    offset += QUOTES_MADE_PER_USER 

    my.each do |h|
      body        = h["body"].to_s # model will strip/squish/de-quote
      attribution = h["attribution"].to_s

      # Uniqueness: body only (case-insensitive) => find by body
      quote = Quote.find_or_create_by!(body: body) do |q|
        q.attribution = attribution
        q.user        = user
      end

      # Attach TAGS_ATTACHED_PER_QUOTE tags per quote; tags can repeat across quotes
      selection = all_tags.sample(TAGS_ATTACHED_PER_QUOTE)
      quote.tags = selection
      quote.save! if quote.changed?
    end
  end
end

# -----------------------------
# Summary
# -----------------------------
puts "[seeds] Done."
puts "  Users:  #{User.count}"
puts "  Tags:   #{Tag.count}"
puts "  Quotes: #{Quote.count}"
links = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM quotes_tags").rows.dig(0,0)
puts "  Quote-Tag associations:  #{links}"
