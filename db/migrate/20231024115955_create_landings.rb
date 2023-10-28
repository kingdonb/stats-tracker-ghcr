class CreateLandings < ActiveRecord::Migration[7.0]
  def change
    create_table :landings do |t|
      t.string :email
      t.string :twitter
      t.string :fediverse
      t.boolean :accept_coc
      t.boolean :printed_stickers_already

      t.timestamps
    end
  end
end
