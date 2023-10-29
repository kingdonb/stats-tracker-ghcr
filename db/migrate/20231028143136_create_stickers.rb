class CreateStickers < ActiveRecord::Migration[7.0]
  def change
    create_table :stickers do |t|
      t.string :image_url

      t.timestamps
    end
  end
end
