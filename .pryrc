if defined?(PryByebug)
  Pry.config.pager = false
  Pry.commands.alias_command 'c', 'continue'
  Pry.commands.alias_command 'f', 'finish'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'

  Pry::Commands.command /^$/, 'repeat last command' do
    _pry_.run_command Pry.history.to_a.last
  end
end
