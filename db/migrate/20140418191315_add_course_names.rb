class AddCourseNames < ActiveRecord::Migration
  def change
    change_table :courses do |t|
      t.string :long_name
    end
  end
end
