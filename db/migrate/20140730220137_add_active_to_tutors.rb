class AddActiveToTutors < ActiveRecord::Migration
  def change
    change_table :tutors do |t|
      t.boolean :active, default: true
    end
  end
end
