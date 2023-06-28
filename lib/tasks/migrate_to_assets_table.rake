desc "Create Asset relationship for AttachmentData"

task create_asset_relationship: :environment do
  def asset_manager
    Services.asset_manager
  end

  def save_asset_id_to_assets(model_id, version, asset_manager_id)
    asset = Asset.new(asset_manager_id:, attachment_data_id: model_id, version:)
    asset.save!
  end

  def get_asset_manager_id(legacy_url_path)
    path = legacy_url_path.sub(/^\//, "")
    response_hash = asset_manager.whitehall_asset(path)
    asset_manager_id = response_hash["id"]
    asset_manager_id[/\/assets\/(.*)/, 1]
  end

  attachment_data = AttachmentData.all

  attachment_data.each do |attachment|
    asset_manager_id = get_asset_manager_id(attachment.file.path)
    save_asset_id_to_assets(attachment.id, Asset.versions["original"], asset_manager_id)

    if (attachment.pdf?)
      asset_manager_id_for_thumbnail = get_asset_manager_id(attachment.file.thumbnail.asset_manager_path)
      save_asset_id_to_assets(attachment.id, Asset.versions["thumbnail"], asset_manager_id_for_thumbnail)
    end
  end
end

