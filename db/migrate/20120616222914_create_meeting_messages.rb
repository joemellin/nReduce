class CreateMeetingMessages < ActiveRecord::Migration
  def change
    create_table :meeting_messages do |t|
      t.string :subject
      t.text :body, :emailed_to
      t.references :user, :meeting
      t.timestamps
    end

    add_index :meeting_messages, :meeting_id
  end
end
