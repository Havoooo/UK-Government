require "securerandom"

module Whitehall
  class PublishingApi
    class Redirect
      attr_reader :base_path

      def initialize(base_path, redirects)
        @redirects = redirects
        @base_path = base_path
      end

      def as_json
        {
          base_path:,
          document_type: "redirect",
          schema_name: "redirect",
          publishing_app: Whitehall::PublishingApp::WHITEHALL,
          update_type: "major",
          redirects:,
        }
      end

    private

      attr_reader :redirects
    end
  end
end
