class CreateAfks < ActiveRecord::Migration[5.2]
  def change
    create_table :afks do |t|
      t.string :message
      t.references :user
      t.timestamps
    end
  end
end
