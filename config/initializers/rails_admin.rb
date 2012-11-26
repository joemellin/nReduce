Kaminari.configure do |config|
  config.page_method_name = :per_page_kaminari
end

# RailsAdmin config file. Generated on June 12, 2012 15:14
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|

  # If your default_local is different from :en, uncomment the following 2 lines and set your default locale here:
  # require 'i18n'
  # I18n.default_locale = :de

  config.authenticate_with do
    admin_required
  end

  config.current_user_method { current_user } # auto-generated

  # If you want to track changes on your models:
  # config.audit_with :history, User

  # Or with a PaperTrail: (you need to install it first)
  # config.audit_with :paper_trail, User

  # Set the admin name here (optional second array element will appear in a beautiful RailsAdmin red ©)
  config.main_app_name = ['Nreduce', 'Admin']
  # or for a dynamic name:
  # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }


  #  ==> Global show view settings
  # Display empty fields in show views
  # config.compact_show_view = false

  #  ==> Global list view settings
  # Number of default rows per-page:
  config.default_items_per_page = 40

  #  ==> Included models
  # Add all excluded models here:
  # config.excluded_models = [Authentication, Checkin, Comment, Instrument, Meeting, Message, Relationship, Startup, User]

  # Add models here if you want to go 'whitelist mode':
  # config.included_models = [Authentication, Checkin, Comment, Instrument, Meeting, Message, Relationship, Startup, User]

  # Application wide tried label methods for models' instances
  # config.label_methods << :description # Default is [:name, :title]

  #  ==> Global models configuration
  # config.models do
  #   # Configuration here will affect all included models in all scopes, handle with care!
  #
  #   list do
  #     # Configuration here will affect all included models in list sections (same for show, export, edit, update, create)
  #
  #     fields_of_type :date do
  #       # Configuration here will affect all date fields, in the list section, for all included models. See README for a comprehensive type list.
  #     end
  #   end
  # end
  #
  #  ==> Model specific configuration
  # Keep in mind that *all* configuration blocks are optional.
  # RailsAdmin will try his best to provide the best defaults for each section, for each field.
  # Try to override as few things as possible, in the most generic way. Try to avoid setting labels for models and attributes, use ActiveRecord I18n API instead.
  # Less code is better code!
  # config.model MyModel do
  #   # Cross-section field configuration
  #   object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #   label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #   label_plural 'My models'      # Same, plural
  #   weight -1                     # Navigation priority. Bigger is higher.
  #   parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #   navigation_label              # Sets dropdown entry's name in navigation. Only for parents!
  #   # Section specific configuration:
  #   list do
  #     filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #     items_per_page 100    # Override default_items_per_page
  #     sort_by :id           # Sort column (default is primary key)
  #     sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     # Here goes the fields configuration for the list view
  #   end
  # end

  # Your model's configuration, to help you get started:

  # All fields marked as 'hidden' won't be shown anywhere in the rails_admin unless you mark them as visible. (visible(true))

  # config.model UserAction do
  #   list do
  #     field :user
  #     field :url_path
  #     field :time_taken
  #     field :ip
  #     field :browser
  #     field :created_at
  #   end
  # end

  # config.model Authentication do
  #   # Found associations:
  #     configure :user, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :provider, :string 
  #     configure :uid, :string 
  #     configure :token, :string 
  #     configure :secret, :string 
  #     configure :user_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  config.model Checkin do
    # Found associations:
    # configure :startup, :belongs_to_association 
    # configure :user, :belongs_to_association 
    # configure :comments, :has_many_association   #   # Found columns:
    # configure :id, :integer 
    # configure :goal, :string 
    # configure :start_why, :string 
    # configure :start_video_url, :string 
    # configure :end_video_url, :string 
    # configure :notes, :text 
    # configure :submitted_at, :datetime 
    # configure :completed_at, :datetime 
    # configure :startup_id, :integer         # Hidden 
    # configure :user_id, :integer         # Hidden 
    # configure :created_at, :datetime 
    # configure :updated_at, :datetime   #   # Sections:
    list do
      field :id
      field :startup
      field :goal
      field :start_video_url
      field :submitted_at
      field :end_video_url
      field :completed_at
      field :start_why
      field :notes
    end
  end
  # config.model Comment do
  #   # Found associations:
  #     configure :user, :belongs_to_association 
  #     configure :checkin, :belongs_to_association 
  #     configure :startup, :has_one_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :content, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :checkin_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Instrument do
  #   # Found associations:
  #   # Found columns:
  #     configure :id, :integer 
  #     configure :data, :string 
  #     configure :inst_type, :integer 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Meeting do
  #   # Found associations:
  #     configure :organizer, :belongs_to_association 
  #     configure :startups, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :location_name, :string 
  #     configure :venue_name, :string 
  #     configure :venue_url, :string 
  #     configure :description, :string 
  #     configure :venue_address, :string 
  #     configure :start_time, :integer 
  #     configure :day_of_week, :integer 
  #     configure :lat, :float 
  #     configure :lng, :float 
  #     configure :organizer_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Message do
  #   # Found associations:
  #     configure :sender, :belongs_to_association 
  #     configure :recipient, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :subject, :string 
  #     configure :folder, :integer 
  #     configure :body, :text 
  #     configure :sent_at, :datetime 
  #     configure :read_at, :datetime 
  #     configure :sender_id, :integer         # Hidden 
  #     configure :recipient_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  #config.model Relationship do
  #   # Found associations:
  #     configure :startup, :belongs_to_association 
  #     configure :connected_with, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :startup_id, :integer         # Hidden 
  #     configure :connected_with_id, :integer         # Hidden 
  #     configure :status, :integer 
  #     configure :created_at, :datetime 
  #     configure :approved_at, :datetime 
  #     configure :rejected_at, :datetime   #   # Sections:
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  #end
  # config.model Startup do
  #   # Found associations:
  #     configure :main_contact, :belongs_to_association 
  #     configure :meeting, :belongs_to_association 
  #     configure :checkins, :has_many_association 
  #     configure :relationships, :has_many_association 
  #     configure :taggings, :has_many_association         # Hidden 
  #     configure :base_tags, :has_many_association         # Hidden 
  #     configure :industry_taggings, :has_many_association         # Hidden 
  #     configure :industries, :has_many_association         # Hidden 
  #     configure :technology_taggings, :has_many_association         # Hidden 
  #     configure :technologies, :has_many_association         # Hidden 
  #     configure :ideology_taggings, :has_many_association         # Hidden 
  #     configure :ideologies, :has_many_association         # Hidden   #   # Found columns:
  #     configure :id, :integer 
  #     configure :name, :string 
  #     configure :location, :string 
  #     configure :one_liner, :string 
  #     configure :phone, :string 
  #     configure :website_url, :string 
  #     configure :stage, :string 
  #     configure :growth_model, :string 
  #     configure :company_goal, :string 
  #     configure :intro_video_url, :string 
  #     configure :onboarding_step, :integer 
  #     configure :team_size, :integer 
  #     configure :active, :boolean 
  #     configure :public, :boolean 
  #     configure :launched_at, :datetime 
  #     configure :logo_file_name, :string         # Hidden 
  #     configure :logo_content_type, :string         # Hidden 
  #     configure :logo_file_size, :integer         # Hidden 
  #     configure :logo_updated_at, :datetime         # Hidden 
  #     configure :logo, :paperclip 
  #     configure :main_contact_id, :integer         # Hidden 
  #     configure :meeting_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :team_members, :serialized   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  config.model User do
  #   # Found associations:
  #     configure :startup, :belongs_to_association 
  #     configure :authentications, :has_many_association 
  #     configure :meeting, :has_one_association 
  #     configure :organized_meetings, :has_many_association 
  #     configure :sent_messages, :has_many_association 
  #     configure :received_messages, :has_many_association 
  #     configure :comments, :has_many_association 
  #     configure :taggings, :has_many_association         # Hidden 
  #     configure :base_tags, :has_many_association         # Hidden 
  #     configure :skill_taggings, :has_many_association         # Hidden 
  #     configure :skills, :has_many_association         # Hidden   #   # Found columns:
  #     configure :id, :integer 
  #     configure :email, :string 
  #     configure :password, :password         # Hidden 
  #     configure :password_confirmation, :password         # Hidden 
  #     configure :reset_password_token, :string         # Hidden 
  #     configure :reset_password_sent_at, :datetime 
  #     configure :remember_created_at, :datetime 
  #     configure :sign_in_count, :integer 
  #     configure :current_sign_in_at, :datetime 
  #     configure :last_sign_in_at, :datetime 
  #     configure :current_sign_in_ip, :string 
  #     configure :last_sign_in_ip, :string 
  #     configure :name, :string 
  #     configure :token, :string 
  #     configure :linkedin_url, :string 
  #     configure :angellist_url, :string 
  #     configure :facebook_url, :string 
  #     configure :twitter, :string 
  #     configure :external_pic_url, :string 
  #     configure :location, :string 
  #     configure :lat, :float 
  #     configure :lng, :float 
  #     configure :admin, :boolean 
  #     configure :mentor, :boolean 
  #     configure :investor, :boolean 
  #     configure :mailchimped, :boolean 
  #     configure :pic_file_name, :string 
  #     configure :pic_content_type, :string 
  #     configure :pic_file_size, :integer 
  #     configure :pic_updated_at, :datetime 
  #     configure :startup_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :phone, :string 
  #     configure :hipchat_username, :string 
  #     configure :hipchat_password, :string   #   # Sections:
    list do
      field :id
      field :name
      field :email
      field :location
      field :startup
      field :twitter
      field :linkedin_url
      field :angellist_url
      field :facebook_url
      field :github_url
      field :dribbble_url
      field :blog_url
      field :meeting
      field :one_liner
      field :bio
      field :phone
      field :intro_video_url
    end
  #   export do; end
  #   show do; end
    edit do
      field :id
      field :name
      field :email
      field :location
      field :startup
      field :twitter
      field :linkedin_url
      field :angellist_url
      field :facebook_url
      field :github_url
      field :dribbble_url
      field :blog_url
      field :meeting
      field :one_liner
      field :phone
      field :bio
      field :intro_video_url
    end
  #   create do; end
  #   update do; end
  end
end
