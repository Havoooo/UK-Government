require "test_helper"
class DefaultNewsOrganisationImageDataTest < ActiveSupport::TestCase
  test "rejects SVG logo uploads" do
    svg_image = File.open(Rails.root.join("test/fixtures/images/test-svg.svg"))
    default_image_data = build(:default_news_organisation_image_data, file: svg_image)

    assert_not default_image_data.valid?
    assert_includes default_image_data.errors.map(&:full_message), "File You are not allowed to upload \"svg\" files, allowed types: jpg, jpeg, gif, png"
  end
end
