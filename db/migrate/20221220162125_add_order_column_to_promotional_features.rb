class AddOrderColumnToPromotionalFeatures < ActiveRecord::Migration[7.0]
  def change
    add_column :promotional_features, :order, :integer
  end
end
