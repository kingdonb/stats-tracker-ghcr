class CreateGithubOrgs < ActiveRecord::Migration[7.0]
  def change
    create_table :github_orgs do |t|
      t.string :name

      t.timestamps
    end
  end
end
