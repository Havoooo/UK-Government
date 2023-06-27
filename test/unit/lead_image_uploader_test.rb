require "test_helper"

class LeadImageUploaderTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess
  setup { LeadImageUploader.enable_processing = true }
  teardown { LeadImageUploader.enable_processing = false }

  test "uses the asset manager and quarantined file storage engine" do
    assert_equal Whitehall::AssetManagerStorage, LeadImageUploader.storage
  end

  test "should only allow JPG, GIF, PNG images" do
    uploader = LeadImageUploader.new
    assert_equal %w[jpg jpeg gif png], uploader.extension_allowlist
  end

  test "should send correctly resized versions of a bitmap image to asset manager" do
    @uploader = LeadImageUploader.new(FactoryBot.create(:person), "mounted-as")

    Services.asset_manager.stubs(:create_whitehall_asset)
    Services.asset_manager.expects(:create_whitehall_asset).with do |value|
      image_path = value[:file].path

      image = MiniMagick::Image.open(image_path)
      assert_equal 300, image[:width], "should be 300px wide, but was #{image[:width]}"
      assert_equal 195, image[:height], "should be 195px high, but was #{image[:height]}"
    end

    Sidekiq::Testing.inline! do
      @uploader.store!(upload_fixture("minister-of-funk.960x640.jpg", "image/jpg"))
    end
  end

  test "should store uploads in a directory that persists across deploys" do
    uploader = LeadImageUploader.new(Person.new(id: 1), "mounted-as")
    assert_match %r{^system}, uploader.store_dir
  end
end
