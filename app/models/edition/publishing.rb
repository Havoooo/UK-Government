module Edition::Publishing
  extend ActiveSupport::Concern

  included do
    has_one :unpublishing, dependent: :destroy

    validates :major_change_published_at, presence: true, if: :published?
    validate :change_note_present!, if: :change_note_required?
    validate :attachment_uploaded_to_asset_manager!, if: :asset_manager_check_required?

    scope :significant_change, -> { where(minor_change: false) }
  end

  module ClassMethods
    def by_major_change_published_at
      order(arel_table[:major_change_published_at].desc)
    end

    def unpublished_as(slug)
      document = Document.at_slug(document_type, slug)
      document && document.latest_edition && document.latest_edition.unpublishing
    end
  end

  def first_published_version?
    published_major_version.nil? || published_major_version == 1
  end

  def first_published_major_version?
    published_major_version == 1 && published_minor_version.zero?
  end

  def published_version
    if published_major_version && published_minor_version
      "#{published_major_version}.#{published_minor_version}"
    end
  end

  def change_note_required?
    if deleted? || superseded?
      false
    elsif draft? && new_record?
      false
    else
      other_editions.published.exists?
    end
  end

  def change_note_present!
    if change_note.blank? && !minor_change
      errors.add(:change_note, "can't be blank")
    end
  end

  def asset_manager_check_required?
    allows_attachments? && published?
  end

  def attachment_uploaded_to_asset_manager!
    errors.add(:attachments, "must have finished uploading.") unless uploaded_to_asset_manager?
  end

  def build_unpublishing(attributes = {})
    super(attributes.merge(slug:, document_type: type))
  end

  def approve_retrospectively
    if force_published?
      self.force_published = false
      save!
    else
      errors.add(:base, "This document has not been force-published")
      false
    end
  end

  def increment_version_number
    if minor_change?
      self.published_major_version = Edition.unscoped.where(document_id:).maximum(:published_major_version) || 1
      self.published_minor_version = (Edition.unscoped.where(document_id:, published_major_version:).maximum(:published_minor_version) || -1) + 1
    else
      self.published_major_version = (Edition.unscoped.where(document_id:).maximum(:published_major_version) || 0) + 1
      self.published_minor_version = 0
    end
  end

  def reset_version_numbers
    self.published_major_version = previous_edition.try(:published_major_version)
    self.published_minor_version = previous_edition.try(:published_minor_version)
  end

  def unpublished?
    !publicly_visible? && unpublishing.present?
  end

  def unpublished_edition
    unpublished? ? unpublishing.edition : nil
  end
end
