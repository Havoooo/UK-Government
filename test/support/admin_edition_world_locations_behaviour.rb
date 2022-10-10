module AdminEditionWorldLocationsBehaviour
  extend ActiveSupport::Concern

  module ClassMethods
    def should_allow_association_between_world_locations_and(document_type)
      edition_class = class_for(document_type)

      view_test "new displays document form with world locations field" do
        get :new

        assert_select "form#new_edition" do
          assert_select "label[for=edition_world_location_ids]", text: "World locations"
          assert_select "#edition_world_location_ids" do |elements|
            assert_equal 1, elements.length
            assert_data_attributes_for_world_locations(
              element: elements.first,
              track_label: new_edition_path(document_type),
            )
          end
        end
      end

      test "creating should create a new document with world locations" do
        world_location1 = create(:world_location)
        world_location2 = create(:world_location)
        attributes = controller_attributes_for(document_type)

        post :create,
             params: {
               edition: attributes.merge(
                 world_location_ids: [world_location1.id, world_location2.id],
               ),
             }

        assert document = edition_class.last
        assert_equal [world_location1, world_location2], document.world_locations
      end

      view_test "edit displays document form with world locations field" do
        edition = create(document_type) # rubocop:disable Rails/SaveBang
        get :edit, params: { id: edition }

        assert_select "form#edit_edition" do
          assert_select "label[for=edition_world_location_ids]", text: "World locations"

          assert_select "#edition_world_location_ids" do |elements|
            assert_equal 1, elements.length
            assert_data_attributes_for_world_locations(
              element: elements.first,
              track_label: edit_edition_path(document_type),
            )
          end
        end
      end

      test "updating should save modified document attributes with world locations" do
        world_location1 = create(:world_location)
        world_location2 = create(:world_location)
        document = create(document_type, world_locations: [world_location2])

        put :update,
            params: { id: document,
                      edition: {
                        world_location_ids: [world_location1.id],
                      } }

        document = document.reload
        assert_equal [world_location1], document.world_locations
      end

      view_test "updating a stale document should render edit page with conflicting document and its world locations" do
        document = create(document_type) # rubocop:disable Rails/SaveBang
        lock_version = document.lock_version
        document.touch

        put :update, params: { id: document, edition: { lock_version: } }

        assert_select ".document.conflict" do
          assert_select "h1", "World locations"
        end
      end
    end
  end

private

  def assert_data_attributes_for_world_locations(element:, track_label:)
    # TODO: Add tracking back in. This is covered in this Trello card https://trello.com/c/eKGeFCQu/975-add-tracking-in-for-associations-on-the-edit-page
    # assert_equal "track-select-click", element["data-module"]
    # assert_equal "worldLocationSelection", element["data-track-category"]
    # assert_equal track_label, element["data-track-label"]
  end
end
