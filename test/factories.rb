def image_fixture_file
  @image_fixture_file ||= File.open(Rails.root.join("test/fixtures/minister-of-funk.960x640.jpg"))
end

def svg_image_fixture_file
  @svg_image_fixture_file ||= File.open(Rails.root.join("test/fixtures/images/test-svg.svg"))
end

Dir[Rails.root.join("test/factories/*.rb")].sort.each { |f| require f }
