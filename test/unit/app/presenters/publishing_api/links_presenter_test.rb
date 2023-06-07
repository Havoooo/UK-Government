require "test_helper"

class PublishingApi::LinksPresenterTest < ActionView::TestCase
  ALL_LINK_TYPES = PublishingApi::LinksPresenter::LINK_NAMES_TO_METHODS_MAP.keys

  def links_for(item, filter_links = ALL_LINK_TYPES)
    LinksPresenter.new(item).extract(filter_links)
  end

  test "extracts content_ids from a detailed guide" do
    document = create(:detailed_guide)
    links = links_for(document)

    assert_equal document.organisations.map(&:content_id), links[:organisations]
  end

  test "returns a links hash derived from the edition" do
    edition = create(:edition)
    create(:specialist_sector, topic_content_id: "content_id_1", edition:, primary: false)

    links = links_for(edition, %i[topics parent organisations])

    assert_equal(
      {
        topics: %w[content_id_1],
        parent: [],
        organisations: [],
        primary_publishing_organisation: [],
        original_primary_publishing_organisation: [],
      },
      links,
    )
  end

  test "it treats the primary specialist sector of the item as the parent" do
    edition = create(:edition)
    create(:specialist_sector, topic_content_id: "content_id_1", edition:, primary: true)
    create(:specialist_sector, topic_content_id: "content_id_2", edition:, primary: false)

    links = links_for(edition, %i[topics parent organisations])

    assert_equal(
      {
        topics: %w[content_id_1 content_id_2],
        parent: %w[content_id_1],
        organisations: [],
        primary_publishing_organisation: [],
        original_primary_publishing_organisation: [],
      },
      links,
    )
  end

  test "correctly sets blank topic and parent values if no specialist sectors are specified" do
    edition = create(:edition)
    links = links_for(edition, %i[topics parent organisations])

    assert_equal(
      {
        topics: [],
        parent: [],
        organisations: [],
        primary_publishing_organisation: [],
        original_primary_publishing_organisation: [],
      },
      links,
    )
  end

  test "adds primary publishing organisation" do
    organisation = create(:organisation)
    edition = create(:detailed_guide, lead_organisations: [organisation])

    links = links_for(edition, [:organisations])

    assert_equal(
      {
        organisations: [organisation.content_id],
        primary_publishing_organisation: [organisation.content_id],
        original_primary_publishing_organisation: [organisation.content_id],
      },
      links,
    )
  end

  test "adds original publishing organisation with the first lead organisation assigned to the first edition" do
    organisation = create(:organisation)
    edition = create(:published_publication, lead_organisations: [organisation])

    new_organisation = create(:organisation)
    new_edition = create(:published_publication, document: edition.document, lead_organisations: [new_organisation])

    links = links_for(new_edition, [:organisations])

    assert_equal(
      {
        organisations: [new_organisation.content_id],
        primary_publishing_organisation: [new_organisation.content_id],
        original_primary_publishing_organisation: [organisation.content_id],
      },
      links,
    )
  end

  test "respects the user-specified ordering of organisations and not their database order" do
    second_lead_organisation = create(:organisation)
    first_lead_organisation = create(:organisation)
    supporting_organisation = create(:organisation)

    edition = create(:document_collection, lead_organisations: [first_lead_organisation, second_lead_organisation], supporting_organisations: [supporting_organisation])

    links = links_for(edition, [:organisations])

    assert_equal(
      {
        organisations: [first_lead_organisation.content_id, second_lead_organisation.content_id, supporting_organisation.content_id],
        primary_publishing_organisation: [first_lead_organisation.content_id],
        original_primary_publishing_organisation: [first_lead_organisation.content_id],
      },
      links,
    )
  end
end
