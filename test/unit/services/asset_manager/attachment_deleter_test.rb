require "test_helper"

class AssetManager::AttachmentDeleterTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  describe AssetManager::AttachmentDeleter do
    let(:worker) { AssetManager::AttachmentDeleter }
    let(:attachment_data) { nil }
    let(:delete_worker) { mock("delete-worker") }

    around do |test|
      AssetManager.stub_const(:AssetDeleter, delete_worker) do
        test.call
      end
    end

    context "when attachment data exists" do
      let(:attachment_data) { create(:attachment_data, file:) }

      before do
        attachment_data.stubs(:deleted?).returns(deleted)
      end

      context "attachment_data has no associated assets" do
        context "when attachment data is not a PDF" do
          let(:file) { File.open(fixture_path.join("sample.rtf")) }

          context "and attachment data is deleted" do
            let(:deleted) { true }

            it "deletes corresponding asset in Asset Manager" do
              delete_worker.expects(:call)
                           .with(nil, attachment_data.file.asset_manager_path)

              worker.call(attachment_data)
            end
          end

          context "and attachment data is not deleted" do
            let(:deleted) { false }

            it "does not delete any assets from Asset Manager" do
              delete_worker.expects(:call).never

              assert AssetManagerDeleteAssetWorker.jobs.empty?
            end
          end
        end

        context "when attachment data is a PDF" do
          let(:file) { File.open(fixture_path.join("simple.pdf")) }

          context "and attachment data is deleted" do
            let(:deleted) { true }

            it "deletes attachment & thumbnail asset in Asset Manager" do
              delete_worker.expects(:call)
                           .with(nil, attachment_data.file.asset_manager_path)
              delete_worker.expects(:call)
                           .with(nil, attachment_data.file.thumbnail.asset_manager_path)

              worker.call(attachment_data)
            end
          end
        end
      end

      context "attachment_data has associated assets" do
        let(:file) { File.open(fixture_path.join("simple.pdf")) }
        let(:original_file_id) { "original_file_id" }
        let(:version_file_id) { "version_file_id" }
        let(:original_asset) do
          Asset.new(attachment_data_id: attachment_data.id, asset_manager_id: original_file_id, version: Asset.versions[:original])
        end
        let(:version_asset) do
          Asset.new(attachment_data_id: attachment_data.id, asset_manager_id: version_file_id, version: Asset.versions[:thumbnail])
        end

        before do
          attachment_data.assets = [original_asset, version_asset]
        end

        context "and attachment data is not deleted" do
          let(:deleted) { false }

          it "does not delete any assets from Asset Manager" do
            delete_worker.expects(:call).never

            worker.call(attachment_data)
          end
        end

        context "and attachment data is deleted" do
          let(:deleted) { true }

          it "deletes attachment & thumbnail asset in Asset Manager" do
            delete_worker.expects(:call).with(original_file_id, nil)
            delete_worker.expects(:call).with(version_file_id, nil)

            worker.call(attachment_data)
          end
        end
      end
    end
  end
end
