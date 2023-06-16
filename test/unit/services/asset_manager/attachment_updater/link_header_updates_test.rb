require "test_helper"

class AssetManager::AttachmentUpdater::LinkHeaderUpdatesTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL
  include Rails.application.routes.url_helpers

  describe AssetManager::AttachmentUpdater::LinkHeaderUpdates do
    let(:updater) { AssetManager::AttachmentUpdater }
    let(:attachment_data) { attachment.attachment_data }
    let(:edition) { FactoryBot.create(:published_edition) }
    let(:parent_document_url) { edition.public_url }
    let(:update_worker) { mock("asset-manager-update-worker") }

    around do |test|
      AssetManager.stub_const(:AssetUpdater, update_worker) do
        test.call
      end
    end

    describe "Attachment Data has no assets" do
      context "when attachment doesn't belong to an edition" do
        let(:attachment) { FactoryBot.create(:file_attachment) }

        it "does not update parent_document_url of any assets" do
          update_worker.expects(:call).never

          updater.call(attachment_data, link_header: true)
        end
      end

      context "when attachment is not a PDF" do
        let(:sample_rtf) { File.open(fixture_path.join("sample.rtf")) }
        let(:attachment) { FactoryBot.create(:file_attachment, file: sample_rtf, attachable: edition) }

        it "sets parent_document_url of corresponding asset" do
          update_worker.expects(:call)
                       .with(nil, attachment_data, attachment.file.asset_manager_path, { "parent_document_url" => parent_document_url })

          updater.call(attachment_data, link_header: true)
        end
      end

      context "when attachment is a PDF" do
        let(:simple_pdf) { File.open(fixture_path.join("simple.pdf")) }
        let(:attachment) { FactoryBot.create(:file_attachment, file: simple_pdf, attachable: edition) }

        it "sets parent_document_url for attachment & its thumbnail" do
          update_worker.expects(:call)
                       .with(nil, attachment_data, attachment.file.asset_manager_path, { "parent_document_url" => parent_document_url })
          update_worker.expects(:call)
                       .with(nil, attachment_data, attachment.file.thumbnail.asset_manager_path, { "parent_document_url" => parent_document_url })

          updater.call(attachment_data, link_header: true)
        end
      end
    end

    describe "Attachment Data has asset(s)" do
      context "when attachment doesn't belong to an edition" do
        let(:attachment) { FactoryBot.create(:file_attachment) }

        it "does not update parent_document_url of any assets" do
          update_worker.expects(:call).never

          updater.call(attachment_data, link_header: true)
        end
      end

      context "when attachment is not a PDF" do
        let(:sample_rtf) { File.open(fixture_path.join("sample.rtf")) }
        let(:attachment) { FactoryBot.create(:file_attachment, file: sample_rtf, attachable: edition) }
        let(:asset) { Asset.new(asset_manager_id: "asset_manager_id", attachment_data_id: attachment_data.id) }

        it "sets parent_document_url of corresponding asset" do
          attachment_data.assets = [asset]

          update_worker.expects(:call)
                       .with(asset.asset_manager_id, attachment_data, nil, { "parent_document_url" => parent_document_url })

          updater.call(attachment_data, link_header: true)
        end
      end

      context "when attachment is a PDF" do
        let(:simple_pdf) { File.open(fixture_path.join("simple.pdf")) }
        let(:attachment) { FactoryBot.create(:file_attachment, file: simple_pdf, attachable: edition) }
        let(:pdf_asset) { Asset.new(asset_manager_id: "asset_manager_id_1", attachment_data_id: attachment_data.id) }
        let(:pdf_thumbnail_asset) { Asset.new(asset_manager_id: "asset_manager_id_2", attachment_data_id: attachment_data.id) }

        it "sets parent_document_url for attachment & its thumbnail" do
          attachment_data.assets = [pdf_asset, pdf_thumbnail_asset]

          update_worker.expects(:call)
                       .with(pdf_asset.asset_manager_id, attachment_data, nil, { "parent_document_url" => parent_document_url })
          update_worker.expects(:call)
                       .with(pdf_thumbnail_asset.asset_manager_id, attachment_data, nil, { "parent_document_url" => parent_document_url })

          updater.call(attachment_data, link_header: true)
        end
      end
    end
  end
end
