#!ruby
# This is the Ruby version of Echo-Sort-Unique-Merge-Join, by Christopher Xu (XuHotdogs@gmail.com)

TMP_ROOT = '/tmp/'

# echo a string into the file
def echo(str, file, append = 1)
  op = '>'
  if append == 1
    op = '>>'
  end
  
  `echo #{str} #{op} #{file}`
end

# uniq the file
def uniq(input, output)
  `uniq #{input} > #{output}`
end

# sort the file
def sort(input, output)
  `sort -n < #{input} > #{output}`
end

# cleanup after we're done
def cleanup
  `rm #{TMP_ROOT}esumj*`
end

# preparing the file
def prep(file)
  path = File.basename(file)
  file.each do |line|
    key, value = line.split
    echo(value, "#{TMP_ROOT}esumj_#{path}_#{key}")
    echo(key, "#{TMP_ROOT}esumj_#{path}_keys")
  end
  
  sort("#{TMP_ROOT}esumj_#{path}_keys", "#{TMP_ROOT}esumj_#{path}_keys_sorted")
  uniq("#{TMP_ROOT}esumj_#{path}_keys_sorted", "#{TMP_ROOT}esumj_#{path}_keys")
end

# Nested Loop Join
def nlj(key, r, s, out)
  rfile = File.open(r, 'rb')
  sfile = File.open(s, 'rb')
  
  rfile.each do |rline|
    sfile.each do |sline|
      echo("\"#{key} #{rline.strip} #{sline.strip}\"", out)
    end
    sfile.rewind
  end
  
  rfile.close
  sfile.close
end

# the last step is to join
def join(r, s, out)
  
  # First, read the keys file
  rkeys = File.open("#{TMP_ROOT}esumj_#{r}_keys", 'rb')
  skeys = File.open("#{TMP_ROOT}esumj_#{s}_keys", 'rb')
  
  # Get the iteraters
  r_iter = rkeys.each
  s_iter = skeys.each
  
  # First keys
  rkey = r_iter.next.to_i
  skey = s_iter.next.to_i
  
  while true
    begin
      if rkey == skey
        # begin join
        nlj(rkey, "#{TMP_ROOT}esumj_#{r}_#{rkey}", "#{TMP_ROOT}esumj_#{s}_#{skey}", out)
        rkey = r_iter.next.to_i
        skey = s_iter.next.to_i
      elsif rkey < skey
        rkey = r_iter.next.to_i
      else
        skey = s_iter.next.to_i
      end
    rescue StopIteration => e
      break
    end
  end
  
  rkeys.close
  skeys.close
end

# inner join r and s, then write to output file
def main(r, s, out)
  
  # Prepare the r file
  File.open(r, 'rb') do |rfile|
    prep(rfile)
  end
  
  # Prepare the s file
  File.open(s, 'rb') do |sfile|
    prep(sfile)
  end
  
  # Join the files
  join(r, s, out)
  
  # ... and cleanup the tmp files
  cleanup
end

# Let's parse the cmd args and run it!
if ARGV[0] == 'help'
  puts 'ruby esumj.rb [input1] [input2] [output]'
  exit 0
end

rfile = ARGV[0]
sfile = ARGV[1]
outfile = ARGV[2]
if File.exists?(rfile) or File.exists?(sfile)
  main(rfile, sfile, outfile)
else
  puts 'ERROR: input file does NOT exist!'
end
