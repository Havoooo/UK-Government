require "test_helper"

class ImageDataTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  test "should be invalid without a file" do
    image_data = build(:image_data, file: nil)
    assert_not image_data.valid?
  end

  test "returns unique auth_bypass_ids from its image's editions" do
    case_study_1 =  create(:case_study)
    case_study_2 =  create(:case_study)
    images_from_first_edition = (1..3).map { |i| Image.new(id: i, edition: case_study_1) }
    images_from_second_edition = (4..6).map { |i| Image.new(id: i, edition: case_study_2) }

    image_data = create(:image_data, images: images_from_first_edition + images_from_second_edition)

    assert_equal [case_study_1.auth_bypass_id, case_study_2.auth_bypass_id], image_data.auth_bypass_ids
  end

  test "rejects images smaller than 960x640" do
    image_data = build_example("50x33_gif.gif")
    assert_not image_data.valid?
    assert image_data.errors.of_kind?(:file, :too_small)
  end

  test "accepts images with 960x640 dimensions" do
    image_data = build_example("960x640_jpeg.jpg")
    assert image_data.valid?
  end

  test "rejects images larger than 960x640" do
    image_data = build_example("960x960_jpeg.jpg")
    assert_not image_data.valid?
    assert image_data.errors.of_kind?(:file, :too_large)
  end

  test "rejects image as 'too small' when it's too large in one dimension but too small in another" do
    image_data = build_example("300x1000_png.png")
    assert_not image_data.valid?
    assert image_data.errors.of_kind?(:file, :too_small)
  end

  test "rejects images with duplicate filename on edition" do
    image_data = build_example("960x640_jpeg.jpg")
    edition = create(:news_article, images: [build(:image, image_data:)])
    image = build(:image, image_data:, edition:)

    image_data.validate_on_image = image

    assert_not image_data.valid?
    assert_equal ["name is not unique. All your file names must be different. Do not use special characters to create another version of the same file name."], image_data.errors[:file]
  end

  test "does not validate unique filename if validate_on_image is not assigned" do
    image_data = build_example("960x640_jpeg.jpg")
    edition = create(:news_article, images: [build(:image, image_data:)])
    build(:image, image_data:, edition:)

    assert image_data.valid?
  end

  test "#bitmap? is false for SVG files" do
    assert_not build_example("test-svg.svg").bitmap?
  end

  test "#bitmap? is true for non-SVG files" do
    assert build_example("50x33_gif.gif").bitmap?
    assert build_example("300x1000_png.png").bitmap?
    assert build_example("960x640_jpeg.jpg").bitmap?
  end

  def build_example(file_name)
    file = File.open(Rails.root.join("test/fixtures/images", file_name))
    build(:image_data, file:)
  end
end
