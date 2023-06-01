class ChangeDownloadCountToBigint < ActiveRecord::Migration[7.0]
  def change
    change_column :packages, :download_count, :bigint
  end
end
