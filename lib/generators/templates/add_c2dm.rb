class AddC2dm < ActiveRecord::Migration
  def self.up
    change_column :rapns_apps, :auth_key, :text, :null => true
  end

  def self.down
    change_column :rapns_apps, :auth_key, :string, :null => true
  end
end
