module MigrationHelpers

  def foreign_key(from_table, from_column, to_table, to_column, suffix=nil, on_delete='SET NULL', on_update='CASCADE')
    constraint_name = "fk_#{from_table}_#{to_table}"
    constraint_name += "_#{suffix}" unless suffix.nil?
    execute %{alter table #{from_table}
      add constraint #{constraint_name}
      foreign key (#{from_column})
      references #{to_table}(#{to_column})
      on delete #{on_delete}
      on update #{on_update}
    }
  end
 
  def drop_foreign_key(from_table, to_table, suffix=nil)
    constraint_name = "fk_#{from_table}_#{to_table}"
    constraint_name += "_#{suffix}" unless suffix.nil?
    report_and_continue = lambda do |ohno|
      puts "#{ohno.class} exception dropping #{constraint_name}"
      puts ohno.message
      puts 'continuing migration...'
    end
    begin
      execute "alter table #{from_table} drop foreign key #{constraint_name}" 
    rescue => ohno 
      report_and_continue.call(ohno)
    end
    begin
      execute "alter table #{from_table} drop key #{constraint_name}" 
    rescue => ohno 
      report_and_continue.call(ohno)
    end
  end
 
end