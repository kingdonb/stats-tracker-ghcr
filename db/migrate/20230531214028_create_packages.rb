class CreatePackages < ActiveRecord::Migration[7.0]
  def change
    create_table :packages do |t|
      t.string :name
      t.references :repository, null: false, foreign_key: true
      t.bigint :download_count

      t.timestamps
    end
  end
end
