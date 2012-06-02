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

ActiveRecord::Schema.define(:version => 20120602204048) do

  create_table "batches", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.string   "venue_name"
    t.string   "venue_url"
    t.string   "venue_description"
    t.integer  "order",             :default => 100000
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "locations", ["order"], :name => "index_locations_on_order"

  create_table "startups", :force => true do |t|
    t.string   "name"
    t.string   "team_members"
    t.string   "location_name"
    t.string   "product_url"
    t.string   "one_liner"
    t.boolean  "active",        :default => true
    t.integer  "user_id"
    t.integer  "location_id"
    t.integer  "batch_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "startups", ["active"], :name => "index_startups_on_active"
  add_index "startups", ["location_id"], :name => "index_startups_on_location_id"

  create_table "users", :force => true do |t|
    t.string   "email",                    :default => "",    :null => false
    t.string   "encrypted_password",       :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",            :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "name"
    t.string   "token"
    t.string   "linkedin_url"
    t.string   "angellist_url"
    t.string   "twitter"
    t.boolean  "spectator",                :default => false
    t.boolean  "startup",                  :default => false
    t.boolean  "mentor",                   :default => false
    t.boolean  "investor",                 :default => false
    t.boolean  "startup_intro_email_sent", :default => false
    t.boolean  "rsvp_email_sent",          :default => false
    t.boolean  "mailchimped",              :default => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
