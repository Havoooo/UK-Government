FactoryBot.define do
  factory :topical_event do
    sequence(:name) { |index| "topical-event-#{index}" }
    summary { "Topical event summary" }
    description { "Topical event description" }
    trait :active do
      start_date { Time.zone.today - 1.month }
      end_date { Time.zone.today + 1.month }
    end

    trait :with_png_logo do
      logo { image_fixture_file }
      logo_alt_text { "Test image" }
    end

    trait :with_svg_logo do
      logo { svg_image_fixture_file }
      logo_alt_text { "Test image" }
    end
  end

  factory :topical_event_with_png_logo, parent: :topical_event, traits: [:with_png_logo]
  factory :topical_event_with_svg_logo, parent: :topical_event, traits: [:with_svg_logo]
end
