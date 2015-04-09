
require "pathname"

def generateKey n, a, i
   out = []

   n.times {
      tmp = 0
      
      out << [i[0]]
      a.each { |el|
         tmp = tmp ^ i[i.length - el - 1]
      }
      i.shift(1)
      i << tmp
   }

   out.flatten!
end

def getSplitString str, splitFunc
   str = splitFunc.call(str)
   str.map! { |x| x.to_i }
end

def to_binary num, n, splitFunc

   return getSplitString("%0#{n}b" % num, splitFunc)
end

def convertStringToBinarySeq str, size, splitFunc
   out = []

   str.each_char { |char|
      out << to_binary(char.ord - $a_offs, size, splitFunc)
   }

   out.flatten!
end

def readText filename

   return File.open(filename, "rt") { |file| file.read }
end

def encodeBinarySeq seq, key
   out = []

   puts "oops!" if (seq.length > key.length)
   seq.each_index { |x| out << (seq[x] ^ key[x]) }
   out
end

def convertBinarySeqTo seq, size, func
   out = []

   j = 0
   tmp = Array.new
   seq.each { |x|
      tmp << x
      if j == (size-1)
         j = 0
         out << tmp if not tmp.empty?
         tmp = Array.new
      else
         j += 1
      end
   }

   func.call(out)
end

def sBoxBegin sbox, key, func

   j = 0
   256.times { |i|
      j = ( j + sbox[i] + key[i.modulo(key.length)] ).modulo(256)
      sbox[i], sbox[j] = sbox[j], sbox[i]
   }

   tmp = []
   j = 0

   s = ""
   1200.times { |i|
      i = (i + 1).modulo(256)
      j = (j + sbox[i]).modulo(256)
      sbox[i], sbox[j] = sbox[j], sbox[i]
      s << "  #{sbox[(sbox[i] + sbox[j]).modulo(256)]}  "
      tmp << to_binary( sbox[(sbox[i] + sbox[j]).modulo(256)], 8, func )
   }
   puts s
   tmp.flatten!
end

#          Method's

def firstMethod func, splitFunc1, splitFunc2, file_in, file_out

   i = getSplitString "00000000000000001111111", splitFunc1 #gets.chomp, splitFunc1 #11111111111111111111111 #00000000000000000000000
   a = getSplitString "5 23", splitFunc2
   a.map! { |x| x - 1 }

   text = readText file_in
   puts "#{text} = text"
   text = convertStringToBinarySeq(text, 8, splitFunc1)
   key = generateKey text.length, a, i
   chipher = encodeBinarySeq(text, key)
   
   puts "#{text.flatten.join} = source text"
   puts "#{key.join} = key"
   puts "#{chipher.join} = encode text"

   res = convertBinarySeqTo(chipher, 8, func)
   puts "#{res} = chiphertext"

   File.open(file_out, "wt") { |file| file.write res }
end

def secondMethod func, splitFunc1, splitFunc2, file_in, file_out

   a = getSplitString "5 23", splitFunc2 #gets.chomp, splitFunc1 #LFSR1
   b = getSplitString "3 31", splitFunc2 #gets.chomp, splitFunc1 #LFSR2
   c = getSplitString "4 39", splitFunc2 #gets.chomp, splitFunc1 #LFSR3

   a.map! { |x| x - 1 }
   b.map! { |x| x - 1 }
   c.map! { |x| x - 1 }

   text = readText file_in
   puts "#{text} = text"
   text = convertStringToBinarySeq(text, 8, splitFunc1)

   i = getSplitString "11111111111111111111111", splitFunc1
   a = generateKey text.length, a, i
   i = getSplitString "1111111111111111111111111111111", splitFunc1
   b = generateKey text.length, b, i
   i = getSplitString "111111111111111111111111111111111111111", splitFunc1
   c = generateKey text.length, c, i

   a.each_index { |x| a[x] = (a[x] & b[x]) | (~a[x] & c[x]) }
   key = a

   chipher = encodeBinarySeq(text, key)

   puts "#{text.flatten.join} = source text"
   puts "#{key.join} = key"
   puts "#{chipher.join} = encode text"

   res = convertBinarySeqTo(chipher, 8, func)
   puts "#{res} = chiphertext"

   File.open(file_out, "w") { |file| file.write res }
end

def digitsConvertion convertFunc, splitFunc, func2, file_in, file_out

   str = readText file_in
   i = getSplitString "11111111111111111111111", func2
   a = getSplitString "5 23", func2
   a.map! { |x| x - 1 }

   str = getSplitString str, splitFunc
   puts str.inspect

   num = []
   str.each { |x| num << to_binary(x, 8, func2) }

   key = generateKey num.flatten.join.length, a, i
   chipher = encodeBinarySeq(num.flatten, key)

   puts "#{num.flatten.join} = source text"
   puts "#{key.join} = key"
   puts "#{chipher.join} = encode text"

   res = convertBinarySeqTo(chipher, 8, convertFunc)
   puts "#{res} = chiphertext"

   File.open(file_out, "w") { |file| file.write res }
end

def thirdMethod func, splitFunc, convert_str, convert_int, file_in, file_out

   isText = true

   text = File.open(file_in, "rb") { |file| file.read }
   puts "#{text} = text"
   text = text.chomp
   if (text =~ /[A-Za-z]/)
      text = convertStringToBinarySeq(text, 8, func)
   else#if (text =~ /[1-9]/)
      num = []
      text = getSplitString text, splitFunc
      text.each { |x| num << to_binary(x, 8, func) }
      text.replace num.flatten
      isText = false
   end

   sbox = Array.new(256) { |i| i }

   bool = true
   key = [1,2,3,4,5]

   key.each { |x| bool = false if x > 255 or x < 0}
   return if not bool

   key = sBoxBegin sbox, key, func

   chipher = encodeBinarySeq text, key

   #puts "#{text.join} = text"
   #puts "#{key[0...text.length].join} = key"
   #puts "#{chipher.join} = encode text"

   res = convertBinarySeqTo(chipher, 8, convert_str) if isText
   res = convertBinarySeqTo(chipher, 8, convert_int) if not isText
   puts "#{res} = chiphertext"

   File.open(file_out, "wb") { |file| file.write res }
end

#           main()

no_split = Proc.new { |x| x.split(//) }
space_split = Proc.new { |x| x.split }

to_string = Proc.new { |out|
   out.map! { |x| x.join }
   out.map! { |x| x.to_i(2) + $a_offs }
   out.map! { |x| x.chr }
   out = out.join
}

to_int = Proc.new { |out|
   out.map! { |x| x.join }
   out.map! { |x| x.to_i(2).to_s }
   out.map! { |x| x << " " }
   out = out.join
}

$a_offs = 0 #"a".ord

=begin
puts "\nFirst method:"
firstMethod to_string, no_split, space_split, "in_string_1.txt", "out_first.txt"
puts "\nSecond method:"
secondMethod to_string, no_split, space_split, "in_string_2.txt", "out_second.txt"

#puts "\nDigits method:"
#digitsConvertion to_int, space_split, no_split

puts "\nThird method, from txt to txt:"
thirdMethod no_split, space_split, to_string, to_int, "in_string_3.txt", "out_third.txt"
puts "\nThird method, from bin to bin:"
thirdMethod no_split, space_split, to_string, to_int, "in_string_3.bin", "out_third.bin"

#thirdMethod no_split, space_split, to_string, to_int, "in_string_3.txt", "out_third.bin"
#thirdMethod no_split, space_split, to_string, to_int, "out_third.bin", "in_string_3.bin"

puts "\n-------------------------------------------------------------------------------"

puts "\n(Test) Third method, from txt to txt:"
thirdMethod no_split, space_split, to_string, to_int, "out_third.txt", "in_string_3.txt"
puts "\n(Test) Third method, from bin to bin:"
thirdMethod no_split, space_split, to_string, to_int, "out_third.bin", "in_string_3.bin"


#thirdMethod no_split, space_split, to_string, to_int, "graph.ico", "cod.ico"
#puts
#thirdMethod no_split, space_split, to_string, to_int, "cod.ico", "cod.ico"
puts "\nCode file:"
secondMethod to_string, no_split, space_split, "123.txt", "123.txt"
=end

def methodMenu file_in, file_out, no_split, space_split, to_string, to_int

   puts
   puts "1: first method"
   puts "2: second method"
   puts "3: third method"
   puts "0: exit"

   method = gets.to_i

   case method
   when 1
      puts "\nFirst method (from \"#{file_in}\" to \"#{file_out}\"):"
      firstMethod to_string, no_split, space_split, file_in, file_out
   when 2
      puts "\nSecond method (from \"#{file_in}\" to \"#{file_out}\"):"
      secondMethod to_string, no_split, space_split, file_in, file_out
   when 3
      puts "\nThird method (from \"#{file_in}\" to \"#{file_out}\"):"
      thirdMethod no_split, space_split, to_string, to_int, file_in, file_out
   when 0
      return
   else
      puts "I don't know 0_o"
   end
end

def fillFile _file

   puts
   puts "1: enter new text in file_in (\"#{_file}\")"
   puts "2: do not enter new text in file_in (\"#{_file}\")"

   ans = gets.to_i

   if ans == 1
   puts "enter text (\"#{_file}\"):"
   text = gets.chomp
   File.open(_file, "wt") { |file| file.write text }
   else
      return
   end

end

ans = 1

while ( ans != 0 )

   puts
   puts "1: use default file_in and file_out"
   puts "2: enter file_in and file_out"
   puts "0: exit"

   ans = gets.to_i

   case ans
   when 1
      file_in = Pathname.new("file_in.txt")
      file_out = Pathname.new("file_out.txt")

      if not file_in.exist?
         puts "enter text in file_in:"
         str = gets.chomp
         File.open(file_in, "wt") { |file| file.write str }
      end
      fillFile file_in
      methodMenu file_in, file_out, no_split, space_split, to_string, to_int
   when 2
      puts "in file:"
      file_in = Pathname.new(gets.chomp)
      puts "out file"
      file_out = Pathname.new(gets.chomp)

      if not file_in.exist?
         puts "enter text in file_in:"
         str = gets.chomp
         File.open(file_in, "wt") { |file| file.write str }
      end
      fillFile file_in
      methodMenu file_in, file_out, no_split, space_split, to_string, to_int
   when 0
      break
   else
      puts "I don't know what to do (0_o)"
      next
   end

end