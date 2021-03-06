class CreateStories < ActiveRecord::Migration
  def self.up
    create_table :stories do |t|
      t.integer :user_id
      t.string :keyword
      t.string :name
      t.text :description
      t.boolean :active

      t.timestamps
    end
  end

  def self.down
    drop_table :stories
  end
end
