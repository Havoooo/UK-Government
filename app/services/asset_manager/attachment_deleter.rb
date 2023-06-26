class AssetManager::AttachmentDeleter
  def self.call(attachment_data)
    return unless attachment_data.deleted?

    if attachment_data.assets.empty?
      delete_asset_for(nil, attachment_data.file)
      delete_asset_for(nil, attachment_data.file.thumbnail) if attachment_data.pdf?
    else
      attachment_data.assets.each do |asset|
        delete_asset_for(asset.asset_manager_id, nil)
      end
    end
  end

  def self.delete_asset_for(asset_manager_id, uploader)
    AssetManager::AssetDeleter.call(asset_manager_id, uploader&.asset_manager_path)
  end
end
