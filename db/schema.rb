# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120609172325) do

  create_table "authentications", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.string   "secret"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "authentications", ["provider", "uid"], :name => "index_authentications_on_provider_and_uid"

  create_table "checkins", :force => true do |t|
    t.string   "start_focus"
    t.string   "start_why"
    t.string   "start_video_url"
    t.string   "end_video_url"
    t.text     "end_comments"
    t.datetime "submitted_at"
    t.datetime "completed_at"
    t.integer  "startup_id"
    t.integer  "user_id"
    t.integer  "week_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "instruments", :force => true do |t|
    t.string   "data"
    t.integer  "inst_type"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "meetings", :force => true do |t|
    t.string   "location_name"
    t.string   "venue_name"
    t.string   "venue_url"
    t.string   "description"
    t.string   "venue_address"
    t.integer  "start_time",    :default => 1830
    t.integer  "day_of_week",   :default => 2
    t.float    "lat"
    t.float    "lng"
    t.integer  "organizer_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "messages", :force => true do |t|
    t.string   "subject"
    t.integer  "folder",       :default => 1
    t.text     "body"
    t.datetime "sent_at"
    t.datetime "read_at"
    t.integer  "sender_id"
    t.integer  "recipient_id"
  end

  add_index "messages", ["recipient_id", "folder", "read_at"], :name => "messages_comp_index"

  create_table "startups", :force => true do |t|
    t.string   "name"
    t.string   "location_name"
    t.string   "product_url"
    t.string   "one_liner"
    t.string   "phone"
    t.string   "team_size"
    t.string   "website_url"
    t.string   "industry"
    t.string   "stage"
    t.string   "growth_model"
    t.string   "company_goal"
    t.string   "intro_video_url"
    t.integer  "onboarding_step",   :default => 1
    t.boolean  "active",            :default => true
    t.boolean  "public",            :default => true
    t.datetime "launched_at"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.integer  "main_contact_id"
    t.integer  "meeting_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "startups", ["public"], :name => "index_startups_on_public"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "name"
    t.string   "token"
    t.string   "linkedin_url"
    t.string   "angellist_url"
    t.string   "facebook_url"
    t.string   "twitter"
    t.string   "external_pic_url"
    t.string   "location"
    t.float    "lat"
    t.float    "lng"
    t.boolean  "admin",                  :default => false
    t.boolean  "startup",                :default => false
    t.boolean  "mentor",                 :default => false
    t.boolean  "investor",               :default => false
    t.boolean  "mailchimped",            :default => false
    t.string   "pic_file_name"
    t.string   "pic_content_type"
    t.integer  "pic_file_size"
    t.datetime "pic_updated_at"
    t.integer  "startup_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "phone"
    t.string   "hipchat_username"
    t.string   "hipchat_password"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
