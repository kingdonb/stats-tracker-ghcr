class CreateVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :versions do |t|
      t.references :package, null: false, foreign_key: true
      t.string :version
      t.integer :download_count

      t.timestamps
    end
  end
end
