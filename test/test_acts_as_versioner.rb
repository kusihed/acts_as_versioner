require 'minitest/autorun'
require 'active_support'
require 'sqlite3'
require 'active_record'
require 'acts_as_versioner'
require 'support/models.rb'
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
load 'support/schema.rb'

class ActsAsVersionerTest < Minitest::Test
  
  def setup
    entry_1 = Entry.new(:name => "Heini")
    entry_1.save
    entry_2 = Entry.new(:name => "Susi")
    entry_2.save
  end  
  
  def test_created_action
    first_entry = Entry.where(:name => "Heini").first
    assert first_entry.get_versions[0].entry_id, 1
    assert first_entry.get_versions[0].action, 0
  end
  
  def test_updated_action
    first_entry = Entry.where(:name => "Heini").first
    first_entry.update(:name => "Werni")
    assert first_entry.get_versions[1].entry_id, 1
    assert first_entry.get_versions[1].action, 1
  end  
  
  def test_destroyed_action
    first_entry = Entry.where(:name => "Heini").first
    first_entry.destroy
    assert first_entry.get_versions[1].entry_id, 1
    assert first_entry.get_versions[1].action, 2
  end  
  
  def test_updated_action_entry_2
    second_entry = Entry.where(:name => "Susi").first
    second_entry.update(:name => "Werni")
    assert second_entry.get_versions[1].entry_id, 2
    assert second_entry.get_versions[1].action, 1
  end  

end