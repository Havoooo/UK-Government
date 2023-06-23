total_count = DocumentCollectionNonWhitehallLink.count

puts "Checking #{total_count} Non whitehall links for documents with the same
content_id"

count = 0
migrated = 0

DocumentCollectionNonWhitehallLink.find_each do |offsite_link|
  puts "#{count} of #{total_count} checked, #{migrated} have been migrated" if (count % 100).zero?
  count += 1

  document = Document.find_by(content_id: offsite_link.content_id)
  next if document.blank?

  offsite_link.document_collection_group_memberships.each do |membership|
    membership.update_column(:document_id, document.id)
  end

  offsite_link.destroy!
  migrated += 1
end

puts "Migration complete. #{migrated} of #{total_count} non-whitehall links
had the the same content_id as a document created on Whitehall and have
have been migrated"
