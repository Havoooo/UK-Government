class Whitehall::AssetManagerStorage < CarrierWave::Storage::Abstract
  def store!(file)
    original_file = file.to_file
    temporary_location = ::File.join(
      Whitehall.asset_manager_tmp_dir,
      SecureRandom.uuid,
      ::File.basename(original_file),
    )

    FileUtils.mkdir_p(::File.dirname(temporary_location))
    FileUtils.cp(original_file, temporary_location)
    legacy_url_path = ::File.join("/government/uploads", uploader.store_path)
    draft = uploader.assets_protected?

    if uploader.model.respond_to?(:attachable)
      attachable_model_class = uploader.model.attachable && uploader.model.attachable.class.to_s
      attachable_model_id = uploader.model.attachable && uploader.model.attachable.id
    end

    auth_bypass_ids = uploader.model.respond_to?(:auth_bypass_ids) ? uploader.model.auth_bypass_ids : []

    AssetManagerCreateWhitehallAssetWorker.perform_async(temporary_location, legacy_url_path, draft, attachable_model_class, attachable_model_id, auth_bypass_ids)
    File.new(uploader.store_path)
  end

  def retrieve!(identifier)
    asset_path = uploader.store_path(identifier)
    File.new(asset_path)
  end

  class File
    def initialize(asset_path)
      @legacy_url_path = ::File.join("/government", "uploads", asset_path)
    end

    def delete
      AssetManagerDeleteAssetWorker.perform_async(@legacy_url_path)
    end

    def url
      URI.join(Plek.asset_root, Addressable::URI.encode(@legacy_url_path)).to_s
    end

    def filename
      ::File.basename(@legacy_url_path)
    end

    def path
      @legacy_url_path
    end

    def asset_manager_path
      path
    end

    def content_type
      MIME::Types.type_for(filename).first.to_s
    end

    def zero_size?
      false
    end
  end
end
