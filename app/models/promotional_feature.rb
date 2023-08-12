class PromotionalFeature < ApplicationRecord
  belongs_to :organisation
  has_many :promotional_feature_items, inverse_of: :promotional_feature, dependent: :destroy

  validates :organisation, :title, presence: true

  accepts_nested_attributes_for :promotional_feature_items

  before_save :set_ordering, if: -> { ordering.blank? }

  def items
    promotional_feature_items
  end

  def has_reached_item_limit?
    items.count == 3
  end

private

  def set_ordering
    self.ordering = (organisation.promotional_features.maximum(:ordering) || 0) + 1
  end
end
