class AddTextFieldToCheckins < ActiveRecord::Migration
  def change
    add_column :checkins, :start_comments, :text

    Checkin.transaction do
      Checkin.all.each{|c| c.update_attribute('start_comments', c.start_why)}
    end
  end
end
