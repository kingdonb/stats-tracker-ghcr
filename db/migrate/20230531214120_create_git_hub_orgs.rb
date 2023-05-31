class CreateGitHubOrgs < ActiveRecord::Migration[7.0]
  def change
    create_table :git_hub_orgs do |t|
      t.string :name

      t.timestamps
    end
  end
end
