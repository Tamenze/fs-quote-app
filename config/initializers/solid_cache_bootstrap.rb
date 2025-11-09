if Rails.env.production?
  begin
    # Avoids boot crashes if table is missing
    unless ActiveRecord::Base.connection.table_exists?("solid_cache_entries")
      Rails.logger.warn("[SolidCache] loading db/cache_schema.rb …")
      load Rails.root.join("db/cache_schema.rb")  # creates solid_cache_entries
    end

    # (Do the same for queue/cable)
    unless ActiveRecord::Base.connection.table_exists?("solid_queue_jobs")
      Rails.logger.warn("[SolidQueue] loading db/queue_schema.rb …")
      load Rails.root.join("db/queue_schema.rb")
    end
    unless ActiveRecord::Base.connection.table_exists?("solid_cable_messages")
      Rails.logger.warn("[SolidCable] loading db/cable_schema.rb …")
      load Rails.root.join("db/cable_schema.rb")
    end
  rescue => e
    Rails.logger.error("[Solid bootstrap] #{e.class}: #{e.message}")
  end
end
