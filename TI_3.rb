
class ChipherIDEA

   attr_writer :key
   attr_accessor :source_key
   attr_accessor :source_text
   attr_accessor :chipher_text

   def initialization

   end

   def readKeyFromFile file
      key = File.open(file, "rb") { |file| file.read }
      
      fkey = []
      key.each_char { |x|
         fkey << "%04x" % x.ord
      }

      fkey
   end

   def saveKeyInFile file, key
      key.each { |x| return if (x.length.to_f / 2.0 > 1.0) }
      key_out = []
      key.each { |x| key_out << x.to_i(16) }
      alert(key_out.inspect)
      File.open(file, "wb") { |file| key_out.each { |x| file.putc x } }
   end

   def readSourceText file, out
      @source_text = []
      File.open(file, "rb") { |file|
         while (not file.eof?)
            @source_text << file.getbyte
         end
      }

      text_word = []
      @source_text.each { |x|
         text_word <<  "%02x" % x
      }

      text_dword = []
      x = 0
      while ( x < text_word.length - 1 ) do
         text_dword << (text_word[x] + text_word[x + 1])
         x += 2
      end

      i = 0
      ftext = []
      (text_dword.length / 4).times {
         block = []
         4.times {
            block << text_dword[i]
            i += 1
         }
         ftext << block
      }

      if (text_dword.length % 4 != 0)
         block = []
         (text_dword.length % 4).times {
            block << text_dword[i]
            i += 1
         }
         (4 - (text_dword.length % 4)).times {
            block << "%04x" % " ".ord
         }
         ftext << block
      end

      @source_text = ftext

      @source_text.each { |x| out.text += "\n" + x.inspect } if out != nil
   end

   def sum a, b
      (a.abs + b.abs) % 2**16
   end

   def mul a, b
      a = 2**16 if a.abs == 0
      b = 2**16 if b.abs == 0
      res = ((a.abs * b.abs) % (2**16 + 1))
      return 0 if res == 2**16
      return res
   end

   def encode out, source_text

      @chipher_text = []

      source_text.map! { |x| x.map! { |y| y = y.to_i(16) } if x != nil }
      @key.map! { |x| x.map! { |y| y = y.to_i(16) } }

      source_text.each { |block|

         break if block == nil

         8.times { |x|
            a = mul(block[0], @key[x][0])
            b = sum(block[1], @key[x][1])
            c = sum(block[2], @key[x][2])
            d = mul(block[3], @key[x][3])

            info("a = #{a} b = #{b} c = #{c} d = #{d}")

            e = a ^ c
            f = b ^ d

            block[0] = (a ^ mul(sum(f, mul(e, @key[x][4])), @key[x][5]))
            block[1] = (c ^ mul(sum(f, mul(e, @key[x][4])), @key[x][5]))
            block[2] = (b ^ sum(mul(e, @key[x][4]), mul(sum(f, mul(e, @key[x][4])), @key[x][5])))
            block[3] = (d ^ sum(mul(e, @key[x][4]), mul(sum(f, mul(e, @key[x][4])), @key[x][5])))

            #output.text += "\n" + "Step #{x}: #{"%04x" % block[0]} #{"%04x" % block[1]} #{"%04x" % block[2]} #{"%04x" % block[3]}"
         }

         tmp_block = block[1]

         block[0] = mul(block[0], @key[8][0])
         block[1] = sum(block[2], @key[8][1])
         block[2] = sum(tmp_block, @key[8][2])
         block[3] = mul(block[3], @key[8][3])

         #output.text += "\n" + "Step 9: #{"%04x" % block[0]} #{"%04x" % block[1]} #{"%04x" % block[2]} #{"%04x" % block[3]}"

         tmp = []
         4.times { |x| tmp << "%04x" % block[x] }
         @chipher_text << tmp
      }

      out.text = ""
      @key.map! { |x| x.map! { |y| "%04x" % y } }
      @chipher_text.each { |x| out.text += "\n" + x.inspect }
   end

   def phi n
      res = n
      i = 2
      while (i*i <= n)
         if (n % i == 0)
            while (n % i == 0)
               n = n / i
            end
            res -= res / i
         end
         i += 1
      end
      
      res -= res / n if (n > 1)
      res
   end

   def prime? n
      return false if (n == 0 || n == 1)
      return true if (n == 2 || n == 3 || n == 5)
      return false if (n % 2 == 0 || n % 3 == 0 || n % 5 == 0)
      bound = Math.sqrt(n)
      i = 7
      j = 11
      while (j <= bound && n % i && n % j)
         i += 6
         j += 6
      end
      return false if (j <= bound || i <= bound && n % i == 0)
      return true
   end

   def inverse_key a, n
      return ((a**(n - 2)) % n) if (prime? n)
      return ((a**(phi(n) - 1)) % n)
   end

   def additive_key a, n
      return (n - a)
   end

   def decode output, out, bDecodeText
      @source_key = []
      @key.map! { |x| x.map! { |y| y.to_i(16) } }
      @key.each { |x| @source_key << x.dup }

      9.times { |x|
         @key[8 - x][0] = inverse_key(@source_key[x][0], 2**16 + 1)
         @key[8 - x][1] = additive_key(@source_key[x][2], 2**16)
         @key[8 - x][2] = additive_key(@source_key[x][1], 2**16)
         @key[8 - x][3] = inverse_key(@source_key[x][3], 2**16 + 1)
      }

      8.times { |x|
         @key[7 - x][4] = @source_key[x][4]
         @key[7 - x][5] = @source_key[x][5]
      }

      @key[0][1], @key[0][2] = @key[0][2], @key[0][1]
      @key[8][1], @key[8][2] = @key[8][2], @key[8][1]

      return unless bDecodeText

      output.text += "\n\nDecode key:"
      @key.map! { |x| x.map! { |y| "%04x" % y } }
      @key.each {|x| output.text += "\n" + x.inspect }

      encode out, @chipher_text if @chipher_text != nil
      encode out, @source_text if @chipher_text == nil
   end

   def generateKeySequance
      genkey = [@key]
      10.times {
         str = ""
         @key.each { |x| str += "%016b" % x.to_i(16) }
         str = str.split(//)
         25.times { str << str.shift }
         str = str.join
         str = str.split(/(.{16})/)
         str.delete_if { |x| x.empty? }
         str.map! { |x| x = "%04x" % x.to_i(2) }
         @key = str
         genkey << @key
      }
      genkey.flatten!
   end

   def generateKey output
      genkey = generateKeySequance

      fkey = []
      i = 0

      8.times { |x|
         tmp = []
         6.times {
            tmp << genkey[i]
            i += 1
         }
         fkey << tmp
      }

      tmp = []
      4.times {
         tmp << genkey[i]
         i += 1
      }

      fkey << tmp
      @key = fkey

      @key.each {|x| output.text += "\n" + x.inspect }
   end

   def writeChipherText file
      tmp_text = @chipher_text.flatten
      chiph = []
      tmp_text.each { |x|
         chiph << x[0..1]
         chiph << x[2..-1]
      }

      File.open(file, "wb") { |file|
         chiph.each { |x|
            file.putc x.to_i(16)
         }
      }
   end
end

Shoes.app title: "IDEA", width: 1050, height: 640 do # 1320

   @chipher = ChipherIDEA.new

   stack margin: 10 do
      
      flow do
         @sou = nil# edit_box width: 270, height: 620
         @int = edit_box width: 270, height: 620 # 470
         @outt = edit_box width: 270, height: 620
      end

      flow top: 0, left: @outt.style[:width] + 5, attach: @outt do
         @source_file = edit_line
         button text: "Open source file", click: proc { open_click() }
      end

      flow top: 30, left: @outt.style[:width] + 5, attach: @outt do
         @chipher_file = edit_line
         button text: "Chipher file", click: proc { open_chipher_click() }
      end

      flow top: 60, left: @outt.style[:width] + 5, attach: @outt do
         @key_file = edit_line
         button text: "Open file with key", click: proc { open_key_click() }
      end

      flow top: 95, left: @outt.style[:width] + 5, attach: @outt do
         @key = []
         8.times { |x| @key[x] = edit_line width: 50 }
         button text: "New key", click: proc { new_key_click() }
      end

      flow top: 130, left: @outt.style[:width] + 5, attach: @outt do
         button text: "Encode", click: proc { encode_click() }
         button text: "Decode", click: proc { decode_click() }
         button text: "Save decode key", click: proc { save_decode_key_click() }
      end

      flow top: 160, left: @outt.style[:width] + 5, attach: @outt do
         @out_s_key = para ""
      end

      flow top: 340, left: @outt.style[:width] + 5, attach: @outt do
         @out_d_key = para ""
      end
   end

   def open_click
      @int.text = ""
      source_path = ask_open_file()
      @source_file.text = source_path
      @chipher.readSourceText source_path, @int
   end

   def open_chipher_click
      @chipher_file.text = ask_open_file()
   end

   def open_key_click
      @key_file.text = ask_open_file()
      @out_s_key.text = "Source key:"

      key = @chipher.readKeyFromFile(@key_file.text)
      @key.each_index { |x| @key[x].text = key[x] }

      @chipher.key = key
      @chipher.generateKey @out_s_key
   end

   def new_key_click
      key = []
      @key.each { |x| key << x.text }
      key.each_index { |x|
         if key[x].length <= 4 
            (4 - key[x].length).times { key[x] = "0" + key[x] }
         else
            alert("You entered wrong key")
            return
         end
      }
      @out_s_key.text = "Source key:"
      @chipher.key = key
      @chipher.generateKey @out_s_key
      @chipher.saveKeyInFile @key_file.text, key
   end

   def encode_click
      #@out_s_key.text = "Source key:"

      #@sou.text = ""
      @chipher.readSourceText @source_file.text, @sou
      @chipher.encode @int, @chipher.source_text
      @chipher.writeChipherText @chipher_file.text

      #@chipher.source_key.each { |x| @out_s_key.text += "\n" + x.inspect }
   end

   def decode_click
      @out_d_key.text = ""
      @chipher.readSourceText @source_file.text, nil
      @chipher.decode @out_d_key, @outt, true
      @chipher.writeChipherText @chipher_file.text
   end

   def save_decode_key_click
      @chipher.decode @out_d_key, @outt, false
      @chipher.saveKeyInFile @key_file.text, @chipher.key
   end

end