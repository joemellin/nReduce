class AddMeetingToUser < ActiveRecord::Migration
  def change
    add_column :users, :meeting_id, :integer

    Startup.where('meeting_id IS NOT NULL').each do |s|
      s.team_members.each{|u| u.meeting_id = s.meeting_id; u.save(:validate => false) }
    end
  end
end
