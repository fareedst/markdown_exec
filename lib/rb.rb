#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

require 'pry'
require 'yaml'
$pdebug = false

# https://github.com/thisredone/rb
File.join(Dir.home, '.rbrc').tap { |f| load f if File.exist?(f) }

def execute(burg, code)
  puts burg.instance_eval(&code)
rescue Errno::EPIPE
  exit
end

public

def tap_inspect(format: nil, name: 'return')
  return self unless $pdebug

  puts "-> #{caller[0].scan(/in `?(\S+)'$/)[0][0]}()" \
       " #{name}: #{method({ json: :to_json,
                             string: :to_s,
                             yaml: :to_yaml }.fetch(format, :inspect)).call}"

  self
end

single_line = ARGV.delete('-l')
ARGV.tap_inspect name: 'ARGV'
code = eval("Proc.new { #{ARGV.join(' ')} }") # rubocop:disable Style/EvalWithLocation
# code = Proc.new {
#   binding.pry
#   grep /Ex/ }
# binding.pry
# code = eval("Proc.new {grep -h }")
# code.tap_inspect name: 'code'
if single_line
  $stdin.each do |l|
    execute(l.chomp, code)
  end
else
  execute($stdin.each_line.tap_inspect(name: 'body'), code)
end

# rubocop:disable Layout/LineLength,Style/BlockComments
=begin

# rb

With 9 lines of Ruby replace most of the command line tools that you use to process text inside of the terminal.

Here's the code

```ruby
#!/usr/bin/env ruby
File.join(Dir.home, '.rbrc').tap { |f| load f if File.exists?(f) }

def execute(_, code)
  puts _.instance_eval(&code)
rescue Errno::EPIPE
  exit
end

single_line = ARGV.delete('-l')
code = eval("Proc.new { #{ARGV.join(' ')} }")
single_line ? STDIN.each { |l| execute(l.chomp, code) } : execute(STDIN.each_line, code)
```

Clone this repo and copy the `rb` file to somewhere in your path (or just copy and paste the above).

With this you can use ruby as a command line utility much more ergonomically than invoking it the standard way.

There's only one switch `-l` which runs your code on each line separately. Otherwise you get an Enumerator that returns the lines of stdin. It's `instance_eval`ed so some methods need `self` to work, eg. `self[-1]`

## Install

Just paste this line into your terminal to install `rb`:
```
sudo curl https://raw.githubusercontent.com/thisredone/rb/master/rb -o /usr/local/bin/rb && sudo chmod +x /usr/local/bin/rb
```

### Examples

::: Extract docker images from running containers

```bash
> docker ps | rb drop 1 | rb -l split[1]

# ubuntu
# postgres
```

::: Display how much time ago containers have exited

```shell
> docker ps -a | rb grep /Exited/ | rb -l 'split.last.ljust(20) + " => " + split(/ {2,}/)[-2]'

# angry_hamilton      => Exited (0) 18 hours ago
# dreamy_lamport      => Exited (0) 3 days ago
# prickly_hypatia     => Exited (0) 2 weeks ago
```

::: Sort `df -h` output by `Use%`

```shell
> df -h | rb 'drop(1).sort_by { |l| l.split[-2].to_f }'

# udev                         3,9G     0  3,9G   0% /dev
# tmpfs                        3,9G     0  3,9G   0% /sys/fs/cgroup
# /dev/sda1                    511M  3,4M  508M   1% /boot/efi
# /dev/sda2                    237M   85M  140M  38% /boot

# or leave the header if you want
> df -h | rb '[first].concat drop(1).sort_by { |l| l.split[-2].to_f }'

# Filesystem                   Size  Used Avail Use% Mounted on
# udev                         3,9G     0  3,9G   0% /dev
# tmpfs                        3,9G     0  3,9G   0% /sys/fs/cgroup
# /dev/sda1                    511M  3,4M  508M   1% /boot/efi
# /dev/sda2                    237M   85M  140M  38% /boot
```

::: Count files by their extension

```shell
> find . -type f | rb 'group_by(&File.method(:extname)).map { |ext, o| "#{ext.chomp}: #{o.size}" }'

# : 3
# .rb: 19
# .md: 1
```

::: This problem http://vegardstikbakke.com/unix/

```ruby
ls | rb 'group_by { |x| x[/\d+/] }.select { |_, y| y.one? }.keys'
```

## Extending rb

The `~/.rbrc` file is loaded if it's available. Anything defined in there will be available inside `rb` scripts.

```ruby
# ~/.rbrc

class String
  def black; "\033[30m#{self}\033[0m" end
  def red;   "\033[31m#{self}\033[0m" end
end
```

```shell
> ls | rb first.red
```

```bash :sum
cat amt.txt | rb "to_a.map{|x|x.to_f}.reduce(&:+)"
```

=end
# rubocop:enable Layout/LineLength,Style/BlockComments
