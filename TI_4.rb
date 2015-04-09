
class ChipherRSA

   attr_reader :encode_key
   attr_reader :decode_key
   attr_reader :phi_r

   def initialization

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

   def gcd a, b
      a = a < 0 ? -a : a
      b = b < 0 ? -b : b
 
      while (a != 0 && b != 0)
         if (a > b)
            a %= b
         else
            b %= a
         end
      end
 
      return (a + b)
   end

   def inverse a, n
      return fast_exp(a, (n - 2), n) if (prime? n)
      return fast_exp(a, (phi(n) - 1), n)
      #return ((a**(n - 2)) % n) if (prime? n)
      #return ((a**(phi(n) - 1)) % n)
   end

   def fast_exp a, z, n # a**z mod n
      a1 = a
      z1 = z
      x = 1
      while (z1 != 0)
         while ((z1 % 2) == 0)
            z1 = z1 / 2
            a1 = (a1 * a1) % n
         end
         z1 -= 1
         x = (x * a1) % n;
      end
      
      return x
   end

   def read_source_file file_in
      bytes = []
      File.open(file_in, "rb") { |file|
         while (not file.eof?)
            bytes << file.getbyte
         end
      }

      return bytes
   end

   def read_chipher_file file_in

      bytes = []
      File.open(file_in, "rb") { |file|
         while (not file.eof?)
            bytes << file.getbyte
         end
      }

      hexBytes = []
      bytes.each { |x|
         hexBytes <<  "%02x" % x
      }

      len = "%00x" % @decode_key[1]
      len = "0" + len if (len.length % 2 != 0)
      len = len.length / 2

      text_dword = []
      x = 0

      if (len != 1)
         while ( x < hexBytes.length - len + 1 ) do   #text_dword << (text_word[x] + text_word[x + 1])
            res = ""
            len.times { |y|
               res += hexBytes[x + y] if (x + y < hexBytes.length)
            }
            text_dword << res
            x += len
         end
      else
         text_dword = hexBytes.dup
         info(text_dword)
      end

      text_dword.map! { |x| x.to_i(16) }

      return text_dword
   end

   def write_chipher_text file_out, text
      if (file_out != nil)

         len = "%00x" % @r
         if (len.length % 2 != 0)
            len = "0" + len
         end

         len = len.length

         word_text = []

         text.each { |x|
            x = "%00x" % x
            while (x.length < len)
               x = "0" + x
            end
            word_text << x
         }

         word_text = word_text.join.split(/(.{2})/)
         word_text.delete_if { |x| x.empty? }

         File.open(file_out, "wb") { |file|
            word_text.each { |x|
               file.putc x.to_i(16)
            }
         }
      end
   end

   def write_source_text file_out, text
      File.open(file_out, "wb") { |file|
         text.each { |x| file.putc x }
      }
   end

   def encode_file text

      chipher_text = []
      text.each { |x|
         chipher_text << (fast_exp(x, @encode_key[0], @encode_key[1]))
      }

      return chipher_text
   end

   def decode_file text

      source_text = []
      text.each { |x|
         source_text << (fast_exp(x, @decode_key[0], @decode_key[1]))
      }

      return source_text
   end

   def setP p
      res = prime? p
      @p = p if res
      alert("P must be prime number!") unless res
      res
   end

   def setQ q
      res = prime? q
      @q = q if res
      alert("Q must be prime number!") unless res
      res
   end

   def setE e

      @e = e
   end

   def setVals
      @r = @p * @q
      @phi_r = phi @r
   end

   def setKeys
      d = inverse @e, @phi_r
      @encode_key = [@e, @r]
      @decode_key = [d, @r]
   end

end

Shoes.app title: "RSA", width: 1200, height: 700 do

   @chipher = ChipherRSA.new

   @source_text = edit_box width: 400, height: 700, margin: 10
   @chipher_text = edit_box width: 400, height: 680, top: 10, left: 400, attach: @source_text

   stack top: 0, left: 410, attach: @chipher_text do
      
      flow do
         @source_file = edit_line width: 200
         button text: "Open source file", click: proc { open_source_click() }
      end

      flow do
         @chipher_file = edit_line width: 200
         button text: "Open out file", click: proc { open_out_file() }
      end

      flow margin_top: 10, margin_bottom: 5 do
         para "p = "
         @p = edit_line width: 60
         para " q = "
         @q = edit_line width: 60
         button text: "Enter", margin_left: 10, click: proc { button_click() }
      end

      flow do
         button text: "Encode", click: proc { encode_click() }
         #button text: "Decode", click: proc { decode_click() }
      end

      flow margin_top: 10, margin_bottom: 5 do
         para "Key: [ "
         @d = edit_line width: 60
         para " , "
         @r_1 = edit_line width: 60
         para " ]  "
         button text: "Decode", click: proc { decode_with_key_click() }
      end

      @phi = para "Phi(r) = "

      para "Attack:"

      flow margin_bottom: 5 do
         para "e = "
         @e = edit_line width: 60
         para " r = "
         @r_2 = edit_line width: 60
         button text: "Decode", click: proc { attack_with_key_click() }
      end 

   end

   def button_click
      return if ((not @chipher.setP @p.text.to_i) or (not @chipher.setQ @q.text.to_i))
      @phi.text = "Phi(r) = " + @chipher.setVals.to_s
      e = ask("Enter e: 1 < e < #{@chipher.phi_r}")
      if ( @chipher.gcd(e.to_i, @chipher.phi_r) == 1 )
         @chipher.setE e.to_i

         @chipher.setKeys
         @phi.text += "\nEncode key: " + @chipher.encode_key.inspect
         @phi.text += "\nDecode key: " + @chipher.decode_key.inspect
      else
         alert("GCD(e, Phi(r)) != 1")
      end
   end

   def open_source_click
      @source_file.text = ask_open_file()
      str = @chipher.read_source_file @source_file.text
      @source_text.text = str
   end

   def open_out_file
      @chipher_file.text = ask_open_file()
   end

   def encode_click
      @source_text.text = ""
      @chipher_text.text = ""
      text = @chipher.read_source_file @source_file.text
      @source_text.text = text
      chiphered_text = @chipher.encode_file text
      @chipher_text.text = chiphered_text
      @chipher.write_chipher_text @chipher_file.text, chiphered_text
   end

   def decode_click
      @chipher_text.text = ""
      text = @chipher.read_source_file @source_file.text
      chiphered_text = @chipher.encode_file text
      @chipher_text.text = @chipher.decode_file chiphered_text
   end

   def decode_with_key_click
      @chipher_text.text = ""
      @chipher.decode_key = [@d.text.to_i, @r_1.text.to_i] if (@chipher.decode_key == nil)
      @chipher.decode_key.replace [@d.text.to_i, @r_1.text.to_i] if (@chipher.decode_key != nil)
      text = @chipher.read_chipher_file @chipher_file.text
      @source_text.text = text
      decoded_file = @chipher.decode_file text
      @chipher_text.text = decoded_file
      @chipher.write_source_text @chipher_file.text, decoded_file
   end

   def attack_with_key_click
      phi_r = @chipher.phi @r_2.text.to_i
      d = @chipher.inverse @e.text.to_i, phi_r

      @chipher_text.text = ""
      @chipher.decode_key = [d, @r_2.text.to_i] if (@chipher.decode_key == nil)
      @chipher.decode_key.replace [d, @r_2.text.to_i] if (@chipher.decode_key != nil)
      text = @chipher.read_chipher_file @chipher_file.text
      decoded_file = @chipher.decode_file text
      @chipher_text.text = decoded_file
      @chipher.write_source_text @chipher_file.text, decoded_file
   end
end