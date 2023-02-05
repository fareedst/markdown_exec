# frozen_string_literal: true

# output standard header for file load during testing
#
def spec_source(file, env_var_name = 'SPEC_DEBUG')
  if (->(val) { val.nil? ? false : !(val.empty? || val == '0') })
     .call(ENV.fetch(env_var_name, nil))
    puts "#{env_var_name}: #{file}"
  end
end
