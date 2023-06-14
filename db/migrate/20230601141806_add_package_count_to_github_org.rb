class AddPackageCountToGithubOrg < ActiveRecord::Migration[7.0]
  def change
    add_column :github_orgs, :package_count, :integer
  end
end
