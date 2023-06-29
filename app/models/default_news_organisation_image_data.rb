class DefaultNewsOrganisationImageData < ApplicationRecord
  mount_uploader :file, BitmapUploader, mount_on: :carrierwave_image
  validates :file, presence: true
end
