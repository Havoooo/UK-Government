class LeadImageUploader < WhitehallUploader
  include CarrierWave::MiniMagick
  process resize_to_fill: [300, 195]

  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  configure do |config|
    config.remove_previously_stored_files_after_update = false
    config.validate_integrity = true
  end

  def image_cache
    file.file.gsub("/govuk/whitehall/carrierwave-tmp/", "") if send("cache_id").present?
  end
end
