class AssetManagerDeleteAssetWorker < WorkerBase
  sidekiq_options queue: "asset_manager"

  def perform(legacy_url_path)
    AssetManager::AssetDeleter.call(nil, legacy_url_path)
  end
end
