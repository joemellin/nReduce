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

ActiveRecord::Schema.define(:version => 20121219210437) do

  create_table "ab_tests", :force => true do |t|
    t.string   "name"
    t.string   "option_a"
    t.string   "option_b"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "account_transactions", :force => true do |t|
    t.string   "attachable_type"
    t.string   "from_account_type"
    t.string   "to_account_type"
    t.integer  "attachable_id"
    t.integer  "amount"
    t.integer  "transaction_type"
    t.integer  "from_account_id"
    t.integer  "to_account_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "account_transactions", ["from_account_id", "to_account_id"], :name => "index_account_transactions_on_from_account_id_and_to_account_id"

  create_table "accounts", :force => true do |t|
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "balance",            :default => 0
    t.integer  "escrow",             :default => 0
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.string   "stripe_customer_id"
  end

  add_index "accounts", ["owner_id", "owner_type"], :name => "index_accounts_on_owner_id_and_owner_type", :unique => true

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

  create_table "awesomes", :force => true do |t|
    t.string   "awsm_type"
    t.integer  "awsm_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "awesomes", ["user_id", "awsm_type", "awsm_id"], :name => "awesomes_index", :unique => true

  create_table "calls", :force => true do |t|
    t.string   "data"
    t.string   "sid"
    t.boolean  "confirmed"
    t.integer  "state"
    t.integer  "scheduled_state"
    t.integer  "duration"
    t.integer  "from_state"
    t.integer  "to_state"
    t.integer  "from_rating"
    t.integer  "to_rating"
    t.datetime "scheduled_at"
    t.integer  "from_id"
    t.integer  "to_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "calls", ["from_id", "created_at"], :name => "index_calls_on_from_id_and_created_at"

  create_table "checkins", :force => true do |t|
    t.string   "goal"
    t.string   "start_why"
    t.string   "start_video_url"
    t.string   "end_video_url"
    t.text     "notes"
    t.datetime "submitted_at"
    t.datetime "completed_at"
    t.integer  "startup_id"
    t.integer  "user_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "awesome_count",   :default => 0
    t.text     "start_comments"
    t.integer  "comment_count",   :default => 0
    t.integer  "week"
    t.integer  "before_video_id"
    t.integer  "video_id"
    t.integer  "measurement_id"
    t.boolean  "accomplished"
    t.string   "next_week_goal"
  end

  add_index "checkins", ["startup_id", "created_at"], :name => "index_checkins_on_startup_id_and_created_at"

  create_table "comments", :force => true do |t|
    t.text     "content"
    t.integer  "user_id"
    t.integer  "checkin_id"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "awesome_count", :default => 0
    t.string   "ancestry"
    t.text     "responder_ids"
    t.boolean  "deleted",       :default => false
    t.integer  "startup_id"
    t.integer  "original_id"
    t.integer  "reply_count",   :default => 0
  end

  add_index "comments", ["checkin_id", "ancestry"], :name => "index_comments_on_checkin_id_and_ancestry"
  add_index "comments", ["startup_id", "created_at"], :name => "index_comments_on_startup_id_and_created_at"

  create_table "conversation_statuses", :force => true do |t|
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.integer  "folder"
    t.datetime "read_at"
    t.datetime "seen_at"
  end

  add_index "conversation_statuses", ["user_id", "read_at", "folder"], :name => "conv_status_user_read_folder"

  create_table "conversations", :force => true do |t|
    t.string   "participant_ids"
    t.datetime "updated_at"
    t.integer  "latest_message_id"
    t.boolean  "team_to_team",      :default => false
  end

  create_table "demo_days", :force => true do |t|
    t.string   "name"
    t.text     "attendee_ids"
    t.date     "day"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "startup_ids"
    t.text     "video_ids"
    t.integer  "index_offset", :default => 0
  end

  create_table "instruments", :force => true do |t|
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "startup_id"
    t.string   "name"
    t.text     "description"
    t.integer  "instrument_type_id"
  end

  add_index "instruments", ["startup_id"], :name => "index_instruments_on_startup_id"

  create_table "invites", :force => true do |t|
    t.string   "email"
    t.string   "code"
    t.string   "msg"
    t.integer  "invite_type"
    t.datetime "expires_at"
    t.datetime "accepted_at"
    t.boolean  "accepted"
    t.integer  "to_id"
    t.integer  "from_id"
    t.integer  "startup_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "name"
    t.datetime "emailed_at"
    t.integer  "weekly_class_id"
  end

  add_index "invites", ["code"], :name => "index_invites_on_code"

  create_table "measurements", :force => true do |t|
    t.integer  "instrument_id"
    t.float    "value"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.float    "delta"
  end

  create_table "meeting_messages", :force => true do |t|
    t.string   "subject"
    t.text     "body"
    t.text     "emailed_to"
    t.integer  "user_id"
    t.integer  "meeting_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "meeting_messages", ["meeting_id"], :name => "index_meeting_messages_on_meeting_id"

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
    t.integer  "from_id"
    t.integer  "conversation_id"
    t.text     "content"
    t.datetime "created_at"
  end

  add_index "messages", ["conversation_id", "created_at"], :name => "messages_conversation_created"

  create_table "notifications", :force => true do |t|
    t.string   "message"
    t.string   "action"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.integer  "user_id"
    t.boolean  "emailed",         :default => false
    t.datetime "read_at"
    t.datetime "created_at"
  end

  add_index "notifications", ["user_id", "read_at"], :name => "index_notifications_on_user_id_and_read_at"

  create_table "nudges", :force => true do |t|
    t.integer  "from_id"
    t.integer  "startup_id"
    t.datetime "seen_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "invite_id"
  end

  create_table "payments", :force => true do |t|
    t.string   "stripe_id"
    t.float    "amount"
    t.integer  "num_helpfuls"
    t.integer  "status"
    t.integer  "account_id"
    t.integer  "user_id"
    t.integer  "account_transaction_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "payments", ["account_id"], :name => "index_payments_on_account_id"

  create_table "questions", :force => true do |t|
    t.string   "content"
    t.string   "tweet_id"
    t.text     "supporter_ids"
    t.integer  "followers_count", :default => 0
    t.datetime "answered_at"
    t.integer  "startup_id"
    t.integer  "user_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.boolean  "tweet",           :default => false
  end

  add_index "questions", ["startup_id", "answered_at", "updated_at"], :name => "startup_answered_updated", :unique => true

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "ratings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "startup_id"
    t.boolean  "interested"
    t.integer  "feedback"
    t.text     "explanation"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "contact_in"
    t.integer  "weakest_element"
    t.boolean  "connected"
  end

  create_table "relationships", :force => true do |t|
    t.integer  "entity_id"
    t.integer  "connected_with_id"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.string   "entity_type"
    t.string   "connected_with_type"
    t.text     "message"
    t.integer  "context"
    t.datetime "pending_at"
    t.boolean  "initiated",           :default => false
    t.datetime "removed_at"
    t.string   "seen_by"
  end

  add_index "relationships", ["entity_id", "entity_type", "status"], :name => "relationship_index"

  create_table "requests", :force => true do |t|
    t.string   "title"
    t.integer  "price"
    t.integer  "num",        :default => 0
    t.text     "data"
    t.text     "extra_data"
    t.integer  "startup_id"
    t.integer  "user_id"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.string   "type"
  end

  add_index "requests", ["num"], :name => "index_requests_on_num"

  create_table "responses", :force => true do |t|
    t.text     "data"
    t.text     "extra_data"
    t.integer  "amount_paid",      :default => 0
    t.integer  "status"
    t.datetime "accepted_at"
    t.datetime "expired_at"
    t.datetime "completed_at"
    t.string   "rejected_because"
    t.boolean  "thanked",          :default => false
    t.integer  "request_id"
    t.integer  "user_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "tip",              :default => 0
    t.integer  "video_id"
  end

  add_index "responses", ["request_id"], :name => "index_responses_on_request_id"

  create_table "rsvps", :force => true do |t|
    t.string   "email"
    t.string   "message"
    t.integer  "user_id"
    t.integer  "startup_id"
    t.integer  "demo_day_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.boolean  "accredited"
  end

  create_table "screenshots", :force => true do |t|
    t.string   "image"
    t.string   "title"
    t.integer  "position"
    t.integer  "user_id"
    t.integer  "startup_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "slide_decks", :force => true do |t|
    t.integer  "startup_id"
    t.text     "slides"
    t.string   "title"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "startups", :force => true do |t|
    t.string   "name"
    t.string   "location"
    t.string   "one_liner"
    t.string   "phone"
    t.string   "website_url"
    t.integer  "stage"
    t.integer  "growth_model"
    t.integer  "company_goal"
    t.string   "intro_video_url"
    t.integer  "onboarding_step",      :default => 1
    t.integer  "team_size",            :default => 1
    t.boolean  "active",               :default => false
    t.boolean  "public",               :default => true
    t.datetime "launched_at"
    t.integer  "main_contact_id"
    t.integer  "meeting_id"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.text     "elevator_pitch"
    t.string   "logo"
    t.float    "rating"
    t.boolean  "checkins_public",      :default => false
    t.string   "pitch_video_url"
    t.integer  "setup"
    t.boolean  "investable",           :default => false
    t.integer  "week"
    t.integer  "intro_video_id"
    t.integer  "pitch_video_id"
    t.text     "business_model"
    t.date     "founding_date"
    t.string   "market_size"
    t.string   "tokbox_session_id"
    t.string   "cached_industry_list"
    t.boolean  "mentorable",           :default => false
    t.datetime "activated_at"
    t.string   "time_zone"
    t.integer  "checkin_day"
  end

  add_index "startups", ["public"], :name => "index_startups_on_public"
  add_index "startups", ["week"], :name => "index_startups_on_week"

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

  create_table "user_actions", :force => true do |t|
    t.integer  "action"
    t.string   "url_path"
    t.string   "ip"
    t.string   "browser"
    t.text     "data"
    t.float    "time_taken"
    t.integer  "user_id"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "session_id"
    t.integer  "ab_test_id"
    t.string   "ab_test_version"
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
    t.boolean  "mailchimped",            :default => false
    t.integer  "startup_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "phone"
    t.string   "hipchat_username"
    t.string   "hipchat_password"
    t.integer  "meeting_id"
    t.integer  "unread_nc",              :default => 0
    t.string   "one_liner"
    t.text     "bio"
    t.string   "github_url"
    t.string   "dribbble_url"
    t.string   "blog_url"
    t.string   "pic"
    t.float    "rating"
    t.string   "intro_video_url"
    t.integer  "roles"
    t.integer  "onboarded"
    t.integer  "email_on"
    t.integer  "setup"
    t.integer  "intro_video_id"
    t.integer  "followers_count"
    t.integer  "weekly_class_id"
    t.string   "country"
    t.string   "cached_skill_list"
    t.string   "cached_industry_list"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["roles"], :name => "index_users_on_roles"
  add_index "users", ["startup_id"], :name => "index_users_on_startup_id"
  add_index "users", ["weekly_class_id"], :name => "index_users_on_weekly_class_id"

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

  create_table "videos", :force => true do |t|
    t.integer  "user_id"
    t.string   "external_id"
    t.string   "local_file_path"
    t.integer  "vimeo_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.boolean  "vimeod",          :default => false
    t.string   "type"
    t.string   "title"
    t.integer  "startup_id"
    t.string   "image"
    t.string   "external_url"
    t.integer  "ecc",             :default => 0
  end

  add_index "videos", ["external_id", "type"], :name => "index_videos_on_external_id_and_type"

  create_table "weekly_classes", :force => true do |t|
    t.integer  "week"
    t.integer  "num_startups",   :default => 0
    t.integer  "num_users",      :default => 0
    t.integer  "num_countries",  :default => 0
    t.integer  "num_industries", :default => 0
    t.text     "clusters"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "weekly_classes", ["week"], :name => "index_weekly_classes_on_week", :unique => true

end
