class AddMeetingToUser < ActiveRecord::Migration
  def change
    add_column :users, :meeting_id, :integer

    Startup.transaction do
      Startup.where('meeting_id IS NOT NULL').each do |s|
        s.team_members.each{|u| u.update_attribute('meeting_id', s.meeting_id) }
      end
    end
  end
end
