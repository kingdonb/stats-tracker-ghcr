class CreateMeasurements < ActiveRecord::Migration[7.0]
  def change
    create_table :measurements do |t|
      t.references :package, null: false, foreign_key: true
      t.bigint :count
      t.datetime :measured_at

      t.timestamps
    end
  end
end
