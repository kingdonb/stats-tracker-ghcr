class CreateVersionMeasurements < ActiveRecord::Migration[7.0]
  def change
    create_table :version_measurements do |t|
      t.references :package, null: false, foreign_key: true
      t.references :version, null: false, foreign_key: true
      t.integer :count
      t.datetime :measured_at

      t.timestamps
    end
  end
end
