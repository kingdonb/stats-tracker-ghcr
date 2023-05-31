class CreateRepositories < ActiveRecord::Migration[7.0]
  def change
    create_table :repositories do |t|
      t.string :name
      t.references :github_org, null: false, foreign_key: true

      t.timestamps
    end
  end
end
