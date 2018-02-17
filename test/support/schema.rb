ActiveRecord::Schema.define(:version => 0) do

  create_table "entries", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "somewhat"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "entry_versions", :force => true do |t|
    t.integer  "entry_id"
    t.integer  "action" 
    t.string   "name",              :limit => 40
    t.string   "somewhat"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "users", :force => true do |t|
    t.string "name"
  end  

end

