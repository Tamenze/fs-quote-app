namespace :data do
  desc "Seed base content (calls db:seed). Idempotent."
  task seed: :environment do
    Rake::Task["db:seed"].invoke
  end

  desc "Reset and reseed using delete_all (adapter-agnostic). DANGEROUS: requires FORCE=1 in production."
  task reset_and_seed: :environment do
    if Rails.env.production? && ENV["FORCE"] != "1"
      abort "Refusing to reset in production without FORCE=1"
    end

    ENV["SEED_RESET"] ||= "1"

    puts "[data] SEED_RESET=#{ENV['SEED_RESET']} -> Clearing tables with delete_all and seeding"
    Rake::Task["db:seed"].reenable
    Rake::Task["db:seed"].invoke
  end

  desc "Seed only if DB appears empty."
  task seed_if_empty: :environment do
    if User.exists? || Tag.exists? || Quote.exists?
      puts "[data] DB not empty; skipping seed."
    else
      puts "[data] DB empty; seeding…"
      Rake::Task["db:seed"].invoke
    end
  end
end
