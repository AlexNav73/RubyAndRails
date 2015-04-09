
require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

require 'pathname'

ruboto_import_widgets :LinearLayout, :EditText, :TextView, :Button

class FillingFile

   def on_create(bundle)
      super

      setContentView(
         linear_layout(:orientation => LinearLayout::VERTICAL) do
            @tv = text_view :text => "Need to fill the file (file was not existed). Enter string:"
            @et = edit_text
            button :text => "Write", :on_click_listener => proc { write_into_file }
            @res = text_view :text => ""
         end)
   end

   def write_into_file
      st = @et.text.toString
      File.open("file.txt", "w") { |file| file.write st }
      @res.setText "Complited!"
   end

end

class MainWindow

   def self.StartProject(context)

      context.start_ruboto_activity do
         def on_create(bundle)
            super

            setTitle "TI lr1"

            setContentView(
               linear_layout(:orientation => LinearLayout::VERTICAL) do
                  linear_layout do
                     @tv = text_view :text => "Key"
                     @key = edit_text
                  end
                  button :text => "Encode", :on_click_listener => proc { encode_file }
                  @res = text_view text: ""
               end)
         end

         def encode_file
            pn = Pathname.new("file.txt")
            context.start_ruboto_activity ("FillingFile") if not pn.exist?

            res  = ""
            str  = File.open("file.txt", "r") { |file| file.read }
            str.chomp
            @res.append "Text: #{str}"
            #str.encode("utf-8")

            key = @key.text.toString
            #key.encode("utf-8")

            if ( /[A-Za-z]/ =~ str ) != nil
               @res.append "\nlanguage: english"
               a_offs = "a".ord #english
            else
               @res.append "russian not supported"
               #a_offs = "а".ord #russian
               #key.chars
               #str.chars
            end

            i = 0
            str.length.times { |j|
               if str[j] != " " and str[j] != "\n"
                  if key[i] != " "
                     offs = (str[j].ord - a_offs) + (key[i].ord - a_offs)
                     a    = a_offs + offs.abs.modulo(26).to_i
                     res << a.chr
                  else
                     res << str[j]
                  end
                  i += 1 if i < key.length
                  i = 0 if i == key.length
               else
                  res << " " if str[j] == " "
                  res << "\n" if str[j] == "\n"
               end
            }

            @res.append "\nanswer: #{res}"

            File.open("file.txt", "w") { |file| file.write res }
         end

      end

   end
end

MainWindow.StartProject($irb)