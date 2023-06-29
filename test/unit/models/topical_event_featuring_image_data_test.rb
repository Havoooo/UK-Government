require "test_helper"

class TopicalEventFeaturingImageDataTest < ActiveSupport::TestCase
  test "rejects SVG logo uploads" do
    svg_image = File.open(Rails.root.join("test/fixtures/images/test-svg.svg"))
    image_data = build(:topical_event_featuring_image_data, file: svg_image)

    assert_not image_data.valid?
    assert_includes image_data.errors.map(&:full_message), "File You are not allowed to upload \"svg\" files, allowed types: jpg, jpeg, gif, png"
  end
end
