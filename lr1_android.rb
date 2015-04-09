
#sadsadsadsa

require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :LinearLayout, :EditText, :TextView, :ListView, :Button

class Arr

   def initialize j
      @arr = Array.new(j) { nil }
   end

   def set_arr new_arr
      @arr.replace new_arr
   end

   def print_arr
      s = ""
      @arr.each_index { |x|
         if (@arr[x] >= 0) and (x < @arr.length - 1)
            @arr[x] = 0 if @arr[x] == 0
            s += "+"
         end
         if x != @arr.length - 1
            s += "#{"%.2f" % @arr[x]}*X[#{x}]"
         else
            s += " = #{"%.2f" % @arr[x]}"
         end
      }
      s[0] = "" if s[0] == "+"
      s
   end

   def div n
      @arr.map! { |el|
         if el != nil and (n != 0 and n != nil)
            el / n
         else
            0
         end
      }
   end

   def mul n
      @arr.map! { |el|
         if el != nil and n != nil
            el * n
         else
            0 
         end
      }
   end

   def return_el index
      if index < @arr.length
         @arr[index]
      end
   end

   def set_val index, val
      if index < @arr.length
         @arr[index] = val
      end
   end

   def set_arr new_arr
      @arr.replace new_arr
   end

   def get_arr
      @arr
   end
end

$irb.start_ruboto_activity do

   def on_create(bundle)
      super

      self.title = "Matrix solution"
      $main_activity = self

      setContentView(
         linear_layout(:orientation => LinearLayout::VERTICAL) do
            linear_layout do
               @i_et = edit_text
               @tv   = text_view :text => "x"
               @j_et = edit_text
               button :text => "Show matrix", :on_click_listener => proc { show_button_click }
               button :text => "Exit", :on_click_listener => proc { exit_button_click }
            end
            @stderr = text_view text: ""
         end)
   end

   def exit_button_click
      finish
   end

   def show_button_click
         
      $i         = @i_et.text.toString.to_i
      $j         = @j_et.text.toString.to_i
      @i_et.text = $i.to_s
      @j_et.text = $j.to_s

      if $i != 0 and $j != 0
         self.start_ruboto_activity do
            def on_create(bundle)
               super
               self.title = "new"
               setContentView(
                  linear_layout(:orientation => LinearLayout::VERTICAL) do
                     linear_layout do
                        @tv_i = text_view :text => "Matrix: " + $i.to_s + "x"
                        @tv_j = text_view :text => $j.to_s + " "
                        button :text => "Gaus", :on_click_listener => proc { solve_gaus_button_click }
                        button :text => "Holeckiy", :on_click_listener => proc { solve_holeckiy_button_click }
                        button :text => "Simple iteration", :on_click_listener => proc { solve_sit_button_click }
                        button :text => "Zeydel", :on_click_listener => proc { solve_zeydel_button_click }
                     end

                     linear_layout do
                        @main_eps_tv = text_view :text => "epsilon = "
                        @main_eps_et = edit_text
                     end

                     linear_layout do
                        @ans_eps_tv = text_view :text => "ans epsilon = "
                        @ans_eps_et = edit_text
                     end

                     $et_arr = Array.new
                     $i.times { |x|
                        objs = Array.new
                        linear_layout do
                           ($j - 1).times { |y|
                              tmp_et = edit_text
                              tmp_tv = text_view :text => "*x[#{y}]"
                              objs << tmp_et
                           }
                           tmp_tv = text_view :text => " = "
                           tmp_et = edit_text
                           objs << tmp_et
                        end
                        $et_arr << objs
                     }

                     $puts   = text_view :text => "\n"
                     $ans_tv = text_view :text => ""

                     linear_layout do
                        @solved_eps_et = edit_text
                        button :text => "Solved?", :on_click_listener => proc { isSolved_button_click }
                     end
                     $isSolved_tv = text_view :text => ""
               end)
         end
      end

      def set_matrix

         $i.times { |x|
            tmp = Array.new
            $j.times { |y|
               a = $et_arr[x][y].text.toString.to_f
               $et_arr[x][y].text = a.to_s
               tmp << a
            }
            $matrix[x].set_arr tmp
         }
      end

      def set_vals
         $isSolved_tv.text     = ""
         $puts.text            = ""
         $ans_tv.text          = ""
         $canBeCheckedBySolved = false
         @eps                  = @main_eps_et.text.toString.to_f
         @epss                 = @ans_eps_et.text.toString.to_i
         @ans                  = Array.new($j-1) { nil }
         $matrix               = Array.new($i) { Arr.new($j) }

         @main_eps_et.text     = @eps.to_s
         @ans_eps_et.text      = @epss.to_s

         if @eps != 0.0 and @epss != 0
            set_matrix
            return true
         else
            $puts.append "Fill epsilon space!\n" if @eps == 0.0
            $puts.append "Fill epsilon of answer space!\n" if @epss == 0
            return false
         end
      end

      def isSolved eps
         ret = true
         $i.times { |x|
            a = 0
            ($j - 1).times { |y|
               a += $matrix[x].return_el(y).to_f * @ans[y]
            }
            ret = false if abs( a - $matrix[x].return_el($j - 1).to_f ) >= eps
         }
         ret
      end

      def isSolved_button_click
         return if not $canBeCheckedBySolved
         eps               = @solved_eps_et.text.toString.to_f
         $isSolved_tv.text = ""

         @solved_eps_et.text = eps.to_s

         set_matrix
         if eps != 0.0
            if isSolved( eps )
               $isSolved_tv.append "Solved!"
            else
               $isSolved_tv.append "Not solved!"
            end
         else
            $isSolved_tv.text = "Enter epsilon of testing answers!"
         end
      end

      def solve_zeydel_button_click
         if set_vals and Prepare($matrix, $i, $j, @ans, 1)
            $canBeCheckedBySolved = true
            @ans.each_index { |i| $ans_tv.append "x[#{i}] = #{"%.#{@epss}f" % @ans[i]}\n" }
         end
      end

      def solve_sit_button_click
         if set_vals and Prepare($matrix, $i, $j, @ans, 0)
            $canBeCheckedBySolved = true
            @ans.each_index { |i| $ans_tv.append "x[#{i}] = #{"%.#{@epss}f" % @ans[i]}\n" }
         end
      end

      def solve_holeckiy_button_click
         if set_vals
            if Holeckiy( $matrix, $i, $j, @ans )
               $canBeCheckedBySolved = true
               @ans.each_index { |i| $ans_tv.append "x[#{i}] = #{"%.#{@epss}f" % @ans[i]}\n" }
            else
               $puts.append "\nThis matrix can't be solved by Holeckiy's method!\n"
            end
         end
      end

      def solve_gaus_button_click
         if set_vals and Gaus( $matrix, $i, $j, @ans )
            $canBeCheckedBySolved = true
            @ans.each_index { |i| $ans_tv.append "x[#{i}] = #{"%.#{@epss}f" % @ans[i]}\n" }
         end
      end

###########################################################################################################################################
############################################################
#                                                          #
#                                                          #
#     Holeckiy method                                      #
#                                                          #
#                                                          #
############################################################

      def isSimmetric matrix, i, j
         trans = Array.new

         (j - 1).times { |y|
            tmp = Array.new

            i.times { |x| tmp << matrix[x].return_el(y).to_f }
            trans << tmp
         }

         isSim = true

         i.times { |x|
            (j - 1).times { |y|
               isSim = false if matrix[x].return_el(y).to_f != trans[x][y].to_f
            }
         }

         isSim
      end

      def Transpon matrix, j
         trans = Array.new

         j.times { |y|
            tmp = Array.new

            j.times { |x| tmp << matrix[x][y].to_f }
            trans << tmp
         }

         trans
      end

      def Holeckiy matrix, i, j, ans
         return false if not isSimmetric(matrix, i, j)

         isHoleckiyCorrect = true

         matrix.map { |e| $puts.append e.print_arr + "\n"}

         l = Array.new(i) { Array.new(j - 1) { 0 } }
         
         (j - 1).times { |y|

            a = 0
            y.times { |k| a -= ( l[y][k] )**2 }    #0.upto(y - 1)
            l[y][y] = Math.sqrt( matrix[y].return_el(y).to_f + a ) if matrix[y].return_el(y).to_f + a > 0
            
            (y + 1).upto(i-1) { |x|
               if x != y
                  a = 0
                  y.times { |k| a -= l[x][k].to_f * l[y][k].to_f }
                  if (matrix[x].return_el(y).to_f + a != 0.0) and (l[y][y] != 0.0)
                     l[x][y] = ( matrix[x].return_el(y).to_f + a ) / l[y][y]
                  else
                     isHoleckiyCorrect = false
                     return false
                  end
               end
            }
         }

         lt = Transpon(l, i)

         i.times { |x| l[x] << matrix[x].return_el(j - 1).to_f }

         $puts.append "\nL matrix:\n\n"
         i.times { |x| matrix[x].set_arr(l[x]) }
         matrix.map { |e| $puts.append e.print_arr + "\n"}

         ys = Array.new(i) { nil }
         i.times { |x|
            a = 0
            k = 0
            while ys[k] != nil
               a += ys[k] * l[x][k]
               k += 1
            end
            if (l[x][j - 1].to_f - a != 0.0) and (l[x][k] != 0.0)
               ys[k] = ( l[x][j - 1].to_f - a ) / l[x][k]
            else
               isHoleckiyCorrect = false
               return false
            end
         }

         i.times { |x| lt[x] << ys[x].to_f }

         $puts.append "\nLt matrix:\n\n"
         i.times { |x| matrix[x].set_arr(lt[x]) }
         matrix.map { |e| $puts.append e.print_arr + "\n"}

         (i - 1).downto(0) { |x|
            a = 0
            k = j - 2
            while ans[k] != nil
               a += ans[k] * lt[x][k]
               k -= 1
            end
            if (lt[x][j - 1].to_f - a != 0.0) and (lt[x][k] != 0.0)
               ans[k] = ( lt[x][j - 1].to_f - a ) / lt[x][k]
            else
               isHoleckiyCorrect = false
               return false
            end
         }
         isHoleckiyCorrect
      end

###########################################################################################################################################
############################################################
#                                                          #
#                                                          #
#     Prepare method                                       #
#                                                          #
#                                                          #
############################################################

      def abs num
         if num < 0
            num * (-1)
         elsif num >= 0
            num
         end
      end

      def Swap matrix, old_i, new_i

         if (old_i != new_i)
            tmp = Array.new
            matrix[old_i].get_arr.each { |el| tmp << el }
            matrix[old_i].set_arr matrix[new_i].get_arr
            matrix[new_i].set_arr tmp
            return true
         end
         false
      end

      def diaganilize matrix, i, global_i, j

         if ($aij < j - 1) and (i < global_i)
            sum = 0
            (j - 1).times { |y|
               next if y == $aij
               sum += abs(matrix[i].return_el(y).to_f)
            }

            if abs( matrix[i].return_el($aij).to_f ) < sum
               next_i = i + 1
               while (next_i < global_i) and not Swap(matrix, i, diaganilize(matrix, next_i, global_i, j)) do
                  next_i += 1
               end
               $aij += 1
               diaganilize(matrix, i + 1, global_i, j)
               return i - 1
            else
               return i
            end
         end
         return i - 1
      end

      def Max arr
         a = arr[0]
         arr.each { |x|
            a = x if x > a
         }
         a
      end

      def NormOfMatrix matrix, i, j
         tmp = Array.new
         i.times { |x|
            a = 0
            (j - 1).times { |y|
               a += abs( matrix[x].return_el(y).to_f )
            }
            tmp << a
         }
         tmp
      end

      def SubMatrix a, b
         i   = a.length
         tmp = Array.new
         i.times { |x|
            tmp << abs( a[x] - b[x] )
         }
         tmp
      end

      def Prepare matrix, i, j, ans, isZeydel

         matrix.map { |e| $puts.append e.print_arr + "\n"}
         puts

         $aij   = 0
         isDiag = true

         diaganilize(matrix, 0, i, j)

         i.times { |x|
            matrix[x].div matrix[x].return_el(x).to_f
            matrix[x].set_val( x, 0 )
            ans[x] = matrix[x].return_el(j - 1).to_f
         }
         isDiag = false if Max( NormOfMatrix matrix, i, j ) > 1 

         $puts.append "\nMatrix has been diaganilized\n\n" if isDiag
         $puts.append "\nMatrix hasn\'t been diaganilized\n\n" if not isDiag

         if isDiag
            matrix.map { |e| $puts.append e.print_arr + "\n"}
            
            simple_iteration matrix, i, j, ans if isZeydel == 0
            Zeydel matrix, i, j, ans if isZeydel == 1
         end
         isDiag
      end
###########################################################################################################################################
############################################################
#                                                          #
#                                                          #
#     Simple iteration method                              #
#                                                          #
#                                                          #
############################################################

      def simple_iteration matrix, i, j, ans

         xk0 = Array.new

         begin
            xk0.replace ans
            tmp = Array.new
            i.times { |x|
               a = 0
               (j - 1).times { |y|
                  a += - matrix[x].return_el(y).to_f * ans[y].to_f
               }
               a += matrix[x].return_el(j - 1).to_f
               tmp << a
            }
            ans.replace tmp
         end while abs( Max( SubMatrix( ans, xk0 ) ) ) > @eps
      end
###########################################################################################################################################
############################################################
#                                                          #
#                                                          #
#     Zeydel method                                        #
#                                                          #
#                                                          #
############################################################

      def Zeydel matrix, i, j, ans

         xk0 = Array.new

         begin
            xk0.replace ans
            i.times { |x|
               ans[x] = 0
               (j - 1).times { |y|
                  ans[x] += - matrix[x].return_el(y).to_f * ans[y].to_f if x != y
               }
               ans[x] += matrix[x].return_el(j - 1).to_f
            }
         end while abs( Max( SubMatrix( ans, xk0 ) ) ) > @eps
      end
###########################################################################################################################################
############################################################
#                                                          #
#                                                          #
#     Gaus method                                          #
#                                                          #
#                                                          #
############################################################

      def TransformMatrix matrix, i, global_i, j

         if ($aii < j - 1) and (i < global_i)
            if matrix[i].return_el($aii).to_f == 0
               next_i = i + 1
               while (next_i < global_i) and not Swap(matrix, i, TransformMatrix(matrix, next_i, global_i, j)) do
                  next_i += 1
               end
               $aii += 1
               TransformMatrix(matrix, i + 1, global_i, j)
            else
               $aii += 1
               TransformMatrix(matrix, i + 1, global_i, j)
               return i
            end
         end

         return i - 1
      end

      def CheckMatrix matrix, i, j
         isCorrect = true
         isInfinity = true

         i.times { |x|
            a = 0
            (j - 1).times { |y|
               a += 1 if matrix[x].return_el(y).to_f == 0.0
            }
            if a == j - 1
               isCorrect = false
               isInfinity = false if matrix[x].return_el(j - 1).to_f != 0.0
            elsif a == j - 2 matrix[x].return_el(j - 1).to_f != 0.0
               $puts.append "\nMatrix has not answer!\n"
               return false
            end
         }

         $puts.append "\nMathix has infinity number of answers!\n" if (not isCorrect) and (isInfinity)
         $puts.append "\nMathix has not answer!\n" if (not isCorrect) and (not isInfinity)
         isCorrect
      end

      def Gaus matrix, i, j, ans
         matrix.map { |e| $puts.append e.print_arr + "\n"}

         $aii = 0
         TransformMatrix matrix, 0, i, j

         $puts.append "\nTransform matrix: \n"
         matrix.map { |e| $puts.append e.print_arr + "\n"}
         return false if not CheckMatrix(matrix, i, j)

         aij = 0

         i.times { |x|
            matrix[x].div matrix[x].return_el(aij).to_f
            for y in (x+1)...i
               matrix[x].mul matrix[y].return_el(aij).to_f
               for k in (0...j)
                  a, b = matrix[y].return_el(k).to_f, matrix[x].return_el(k).to_f
                  matrix[y].set_val( k, a - b )
               end
               matrix[x].div matrix[x].return_el(aij).to_f
            end
            aij += 1
            return false if not CheckMatrix(matrix, i, j)
         }

         return false if not CheckMatrix(matrix, i, j)
         $puts.append "\n"
         matrix.map { |e| $puts.append e.print_arr + "\n"}

         x = i - 1
         while x >= 0
            y = j - 2
            while y >= 0
               if ans[y] == nil
                  if matrix[x].return_el(y) != 0
                     ans[y] = matrix[x].return_el(j-1) / matrix[x].return_el(y).to_f
                     #break
                  end
               else
                  matrix[x].set_val( j - 1, matrix[x].return_el(j-1) - (ans[y] * matrix[x].return_el(y).to_f) )
               end
               y -= 1
            end
            x -= 1
         end
         return true
      end
###########################################################################################################################################
   end
  end
end