require "test_helper"
require "govuk_schemas"

class PublishStaticPagesTest < ActiveSupport::TestCase
  test "sends static pages to rummager and publishing api" do
    Whitehall::FakeRummageableIndex.any_instance.expects(:add).at_least_once.with(kind_of(Hash))
    publisher = PublishStaticPages.new
    expect_publishing(publisher.pages)

    PublishStaticPages.new.publish
  end

  test "static pages presented to the publishing api are valid according to the relevant schema" do
    publisher = PublishStaticPages.new
    publisher.pages.each do |page|
      presented = publisher.present_for_publishing_api(page)
      expect_valid_for_schema(presented[:content])
    end
  end

  def expect_publishing(pages)
    pages.each do |page|
      Services.publishing_api.expects(:put_content)
        .with(
          page[:content_id],
          has_entries(
            document_type: page[:document_type],
            schema_name: (page[:schema_name] || "placeholder"),
            base_path: page[:base_path],
            title: page[:title],
            update_type: "minor",
          ),
        )

      Services.publishing_api.expects(:publish)
        .with(page[:content_id], nil, locale: "en")
    end
  end

  def expect_valid_for_schema(presented_page)
    validator = GovukSchemas::Validator.new(
      presented_page[:schema_name],
      "publisher",
      presented_page,
    )
    assert validator.valid?, validator.error_message
  end
end
