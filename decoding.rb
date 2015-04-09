
def minOrmaxEl arr, min = true
   if not arr.empty?
      a = arr[0]
      arr.each { |x|
         a = x if (a > x) and min
         a = x if (a < x) and (not min)
      }
      a
   else
      nil
   end
end

def FreqMethod str
   tmp = Array.new

   str.length.times { |x|
      a = 1
      y = x

      while (y + 1 < str.length)
         if (str[x] == str[y + 1]) and (str[x] != "0")
            a += 1 
            str[y + 1] = "0"
         end
         y += 1
      end
      tmp[str[x].ord - "a".ord] = (100 * a.to_f / str.length.to_f).round(1) if str[x] != "0"
   }
   tmp
end

text = File.open("out.txt", "r") { |file| file.read }
puts "#{text}\n#{text.length}"

arrs = Array.new
freqs = Array.new
th = Array.new

(text.length - 1).times { |offs|
   th << Thread.new {
   3.upto(text.length / 2) { |i|
      arr  = Array.new
      break if i + offs >= text.length
      str = ""
      offs.upto(offs + i - 1) { |x| str << text[x] }

      (offs + str.length).upto(text.length - str.length) { |j|
         check_str = ""
         (j).upto(j + str.length - 1) { |y| check_str << text[y] }
         if str == check_str
            arr << j - offs
            puts "(#{str}) keylen = #{j - offs}"
            freqs << FreqMethod(str)
         end
      }

      if not arr.empty?
         del = Array.new(minOrmaxEl arr) { |h| h+1 }

         arr.each { |x|
            del.delete_if { |n|
               a = x.to_i.modulo(n)
               a != 0 or n == 1
            }
         }

         arrs << minOrmaxEl(del, false)
      end
   }
   }
}

th.map { |x| x.join}

arrs = arrs.compact
puts "\narr of dividers: " + arrs.inspect

#puts "\nfreqs: " + freqs.inspect
exit if arrs.empty?

keylens = Array.new(minOrmaxEl(arrs, false) + 1) { |e| e = 0 }

arrs.length.times { |x|
   arrs.length.times { |y|
      if x != y
         a = arrs[y].to_i.modulo(arrs[x])
         keylens[arrs[x]] += 1 if (a == 0)
      end
   }
}

i   = 0
max = keylens[0]

keylens.each_index { |x|
   if keylens[x] > max
      i = x
      max = keylens[x]
   end
}

puts "\nkey length = #{i}"

=begin
#freq = [8.1, 1.4, 2.7, 3.9, 13, 2.9, 2, 5.2, 6.5, 0.2, 0.4, 3.4, 2.5, 7.2, 7.9, 2, 6.9, 6.1, 10.5, 2.4, 0.9, 1.5, 0.2, 1.9, 0.1]
text_freq = []
"a".upto("z") { |x|
   a = 0
   text.each_char { |y|
      a += 1 if x == y
   }
   text_freq << ((a.to_f / text.length.to_f) * 100).round(1) if a != 0
   text_freq << 0 if a == 0
}

puts text_freq.inspect


key = ""
keylen = minOrmaxEl(keylens, false) - 1

keylen.times { |x|
   a = text_freq[text[x].ord - "a".ord]
   freq.each_index { |i|
      key << i + "a".ord if (freq[i] - a).abs < 0.5
   }
}
=end

#puts "KEY: #{key}"