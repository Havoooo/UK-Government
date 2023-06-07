require "test_helper"

class LeadImagePresenterHelperTest < ActiveSupport::TestCase
  test "should use placeholder image if none had been uploaded" do
    presenter = stub("Target", images: [], lead_organisations: [], organisations: []).extend(LeadImagePresenterHelper)
    assert_match %r{placeholder}, presenter.lead_image_url
    assert_equal "", presenter.lead_image_alt_text
  end

  test "should use empty string if no alt_text is provided" do
    presenter = stub("Target", images: [], lead_organisations: [], organisations: []).extend(LeadImagePresenterHelper)
    file = stub("File", content_type: "image/jpg")
    uploader = stub("Uploader", file:)
    image_data = stub("ImageData", file: uploader)
    image = stub("Image", alt_text: nil, image_data:)
    presenter.stubs(images: [image])
    assert_equal "", presenter.lead_image_alt_text
  end

  test "should use first image with version :s300 if an image is present" do
    presenter = stub("Target", images: [], lead_organisations: [], organisations: []).extend(LeadImagePresenterHelper)
    file = stub("File", content_type: "image/jpg")
    uploader = stub("Uploader", file:)
    image_data = stub("ImageData", file: uploader)
    image = stub("Image", alt_text: "alt_text", image_data:)
    uploader.expects(:url).with(:s300).returns("url")
    presenter.stubs(images: [image])
    assert_equal "url", presenter.lead_image_url
    assert_equal "alt_text", presenter.lead_image_alt_text
  end

  test "uses unversioned url if the image is an SVG" do
    presenter = stub("Target", images: [], lead_organisations: [], organisations: []).extend(LeadImagePresenterHelper)
    file = stub("File", content_type: "image/svg+xml")
    uploader = stub("Uploader", file:)
    image_data = stub("ImageData", file: uploader)
    image = stub("Image", alt_text: "alt_text", image_data:)
    uploader.expects(:url).with.returns("url")
    presenter.stubs(images: [image])
    assert_equal "url", presenter.lead_image_url
    assert_equal "alt_text", presenter.lead_image_alt_text
  end
end
