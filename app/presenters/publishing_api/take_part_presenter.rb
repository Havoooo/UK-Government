module PublishingApi
  class TakePartPresenter
    attr_accessor :item, :update_type

    def initialize(item, update_type: nil)
      self.item = item
      self.update_type = update_type || "major"
    end

    delegate :content_id, to: :item

    def content
      content = BaseItemPresenter.new(
        item,
        update_type:,
      ).base_attributes

      content.merge!(
        description: item.summary,
        details:,
        document_type: "take_part",
        public_updated_at: item.updated_at,
        rendering_app: Whitehall::RenderingApp::GOVERNMENT_FRONTEND,
        schema_name: "take_part",
      )
      content.merge!(PayloadBuilder::PolymorphicPath.for(item))
    end

    def links
      {}
    end

  private

    def details
      {
        body: Whitehall::GovspeakRenderer.new.govspeak_to_html(item.body),
        image: {
          url: item.image_url(:s300),
          alt_text: item.image_alt_text,
        },
        ordering: item.ordering,
      }
    end
  end
end
