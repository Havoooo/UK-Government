desc "Republish all documents with non-pdf attachments"
task republish_non_pdf_attachments: :environment do
  document_ids = Attachment.joins(:attachment_data)
                           .joins("JOIN editions ON editions.id = attachments.attachable_id AND attachments.attachable_type = 'Edition'")
                           .where.not(deleted: true)
                           .where.not(attachment_data: { content_type: "application/pdf" })
                           .where.not(attachable: nil)
                           .where(editions: { state: "published" }).distinct.pluck(:document_id)

  puts "#{document_ids.length} items to republish"

  document_ids.each do |document_id|
    PublishingApiDocumentRepublishingWorker.perform_async_in_queue("bulk_republishing", document_id, true)
  end
end
