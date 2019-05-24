class CreateMyAppUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :my_app_users do |t|
      t.string :name

      t.timestamps
    end
  end
end
