
require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

class Tabl

   def initialize
      @x = Array.new
      @y = Array.new
      @j = -1
   end

   def Check
      @x.each_index { |i|
         if ( i+1 < @x.length ) and ( @x[i] == @x[i+1] )
            @x.delete_at(i+1)
         elsif ( i+1 < @y.length ) and ( @y[i] == @y[i+1] )
               @y.delete_at(i+1)
         end
      }
      @j = @x.length - 1
   end

   def addPoint x, y
      @x << x
      @y << y
      @j += 1
   end

   def get_xj j
      @x[j]
   end

   def get_yj j
      @y[j]
   end

   def getLength
      @j + 1
   end
end

############################################################
#                                                          #
#                                                          #
#     Lagranj pilinom                                      #
#                                                          #
#                                                          #
############################################################

def Lagranj main, xj, j

   lx = 0.0
   i = j

   i.times { |x|
      a = 1.0
      j.times { |y| 
         a *= ( xj.to_f - main.get_xj(y).to_f ) / ( main.get_xj(x).to_f - main.get_xj(y).to_f ) if (x != y)
      }
      a *= main.get_yj(x)
      lx += a
   }

   lx
end

######################################################################################################
############################################################
#                                                          #
#                                                          #
#     Newton pilinom                                       #
#                                                          #
#                                                          #
############################################################

def Newton main, xj, j

   tmp = Array.new
   tmp << main.get_yj(0).to_f

   1.upto(j - 1) { |x|
      b = main.get_yj(x).to_f
      c = 1.0
      x.times { |y|
         c = 1.0
         y.times { |z|
            c *= main.get_xj(x).to_f - main.get_xj(z).to_f
         }
         b -= tmp[y] * c
      }
      c = 1.0
      x.times { |y|
         c *= main.get_xj(x).to_f - main.get_xj(y).to_f
      }
      tmp << b / c
   }

   px = tmp[0]
   1.upto(j - 1) { |x|
      a = 1.0
      x.times { |y|
         a *= xj - main.get_xj(y).to_f
      }
      px += a * tmp[x]
   }

   px
end

#########################################################################################

class CanvasView < android.view.View

   java_import "android.graphics.Path"
   java_import "android.graphics.Color"
   java_import "android.graphics.Paint"
   java_import "android.graphics.RectF"
   java_import "android.graphics.Bitmap"
   java_import "android.graphics.Canvas"

   def initialize(c)
      @canvas = Canvas.new

      @paint = Paint.new
      @paint.setFlags(Paint::ANTI_ALIAS_FLAG);
      @paint.setARGB(255, 255, 0, 0)
      @paint.setStyle(Paint::Style::STROKE)
      @paint.setStrokeWidth(4)

      @tablica_l = Tabl.new
      @tablica_n = Tabl.new

      $x_count.times { |x|
         @tablica_l.addPoint(200 + 50*$var[x][0], 400 + (-25)*$var[x][1])
         @tablica_n.addPoint(200 + 50*$var[x][0], 1300 + (-25)*$var[x][1])
      }

      @tablica_l.Check
      @tablica_n.Check
      super
   end

   def FillMatrix bLagranj
      tmp = []

      down = 0
      up = @width

      #down = @tablica_l.get_xj(0) if bLagranj
      #down = @tablica_n.get_xj(0) if not bLagranj

      #up = @tablica_l.get_xj($x_count-1) if bLagranj
      #up = @tablica_n.get_xj($x_count-1) if not bLagranj

      down.step(up, 6) { |x|

         tm = []

         a = Lagranj(@tablica_l, x, @tablica_l.getLength) if bLagranj
         a = Newton(@tablica_n, x, @tablica_n.getLength) if not bLagranj

         tm << x

         if (bLagranj)
            tm << a if (a < @height / 2)
            tm << @height / 2 if (a >= @height / 2)
         else
            tm << a if (a > @height / 2)
            tm << @height / 2 if (a <= @height / 2)
         end

         tmp << tm
      }

      return tmp
   end

   def onDraw(canvas)
      super
      if @bitmap
         if (@last_x >= @max_x)
            @last_x = 0
         end

         @canvas.drawColor(Color::WHITE)

         #@tablica_l.getLength.times { |j|
            #@canvas.drawCircle(@tablica_l.get_xj(j), @tablica_l.get_yj(j), 20.0, @paint)
            #@canvas.drawPoint(@tablica_l.get_xj(j), @tablica_l.get_yj(j), @paint)

            #@canvas.drawCircle(@tablica_n.get_xj(j), @tablica_n.get_yj(j), 20.0, @paint)
            #@canvas.drawPoint(@tablica_n.get_xj(j), @tablica_n.get_yj(j), @paint)
         #}

         @canvas.drawLine(1, 0, 1, @height, @paint)
         @canvas.drawLine(1, 400, @width, 400, @paint)
         @canvas.drawLine(1, 1300, @width, 1300, @paint)

         @paint.setTextSize(30)
         @canvas.drawText("Lagranj", 50, 60, @paint)
         @canvas.drawText("Newton", 70, 900, @paint)
         @canvas.drawText("Y", 4, 40, @paint)
         @canvas.drawText("Y", 4, 870, @paint)
         @canvas.drawText("X", @width - 30, 370, @paint)
         @canvas.drawText("X", @width - 30, 1270, @paint)

         thr_lagr = Thread.new {

            lagr = FillMatrix(true) 

            (lagr.length - 1).times { |x|
               @canvas.drawLine(lagr[x][0], lagr[x][1], lagr[x+1][0], lagr[x+1][1], @paint)
            }
         }

         thr_newt = Thread.new {

            newt = FillMatrix(false)

            (newt.length - 1).times { |x|
               @canvas.drawLine(newt[x][0], newt[x][1], newt[x+1][0], newt[x+1][1], @paint)
            }
         }

         thr_lagr.join
         thr_newt.join

         @paint.setARGB(255, 0, 0, 0)
         @canvas.drawLine(0, @height / 2, @width, @height / 2, @paint)
         @paint.setARGB(255, 255, 0, 0)

         canvas.drawBitmap(@bitmap, 0, 0, nil)
      end
   end

   def onSizeChanged(w, h, oldw, oldh)
      @bitmap  = Bitmap.createBitmap(w, h, Bitmap::Config::RGB_565)
      @width   = w
      @height  = h
      @max_x   = w + ((@width < @height) ? 0 : 50)
      @last_x  = @max_x

      @canvas.setBitmap(@bitmap)
      @canvas.drawColor(Color::WHITE)
   end

   #def OnPointSet(x, y)
      #@tablica.addPoint(x, y)
      #invalidate
   #end
end

class GrafCanvas

   java_import "android.content.Context"

   def on_create(bundle)
      super

      @canvas_view = CanvasView.new(@ruboto_java_instance)
      self.content_view = @canvas_view
   end

   #def on_touch_event(event)
      #index = event.find_pointer_index(0)
      #x = event.getX(index)
      #y = event.getY(index)
      #@canvas_view.OnPointSet(x, y - 150)
      #true
   #end
end

ruboto_import_widgets :LinearLayout, :EditText, :TextView, :Button

class MainWindow

   def self.StartProject(context)

      context.start_ruboto_activity do
         def on_create(bundle)
            super

            setTitle "Spline"
            $var = [[1, -0.16], [2, 0.01], [3, 0.1], [4, 0.16], [5, 0.05], [6, 0.35], [7, 0.19], [8, 0.5], [9, 0.74], [10, 1.03], [11, 1.06], [12, 1.49], [13, 1.79], [14, 2.03]]
            #$var = [[1, 1], [2, 4], [3, 9], [4, 16], [5, 25], [6, 36], [7, 49], [8, 64], [9, 81], [10, 100], [11, 121], [12, 144], [13, 169], [14, 196]]
            editTextArray = []

            setContentView(
               linear_layout(:orientation => LinearLayout::VERTICAL) do
                  @about_et = text_view :text => "Approximation of function by using Lagranj and Newton polinoms"
                  linear_layout do
                     @l_et = edit_text
                     button :text => "Lagranj", :on_click_listener => proc { Lagranj_button_click() }
                     @l_tv = text_view :text => ""
                  end
                  linear_layout do
                     @n_et = edit_text
                     button :text => "Newton", :on_click_listener => proc { Newton_button_click() }
                     @n_tv = text_view :text => ""
                  end
                  linear_layout do
                     x_tv = text_view :text => "count of x-s"
                     @et = edit_text
                     button :text => "Draw", :on_click_listener => proc { Draw_button_click self }
                     @err = text_view text: ""
                  end

                  var_tv = text_view text: "\nX-s and Y-s of 9 variant:\n"
                  $var.map { |x|
                     tv = text_view text: "X = #{x[0]}   Y = #{x[1]}"
                     editTextArray << tv
                  }
               end)
         end

         def Lagranj_button_click
            @l_tv.text = ""
            return if (@l_et.text.toString.to_f == 0.0)

            x = @l_et.text.toString.to_f
            x = 0 if @l_et.text.toString.to_f == 0.0
            l_tabl = Tabl.new

            14.times { |x|
               l_tabl.addPoint($var[x][0], $var[x][1])
            }

            y = Lagranj(l_tabl, x, l_tabl.getLength)
            @l_tv.text = "   x = #{x}   y = #{y}"
         end

         def Newton_button_click
            @n_tv.text = ""
            return if (@n_et.text.toString.to_f == 0.0)

            x = @n_et.text.toString.to_f
            x = 0 if @n_et.text.toString.to_f == 0.0
            n_tabl = Tabl.new

            14.times { |x|
               n_tabl.addPoint($var[x][0], $var[x][1])
            }

            y = Newton(n_tabl, x, n_tabl.getLength)
            @n_tv.text = "   x = #{x}   y = #{y}"
         end

         def Draw_button_click context
            if (@et.text.toString.to_i > 0) and (@et.text.toString.to_i < $var.length + 1)
               $Lagranj  = true
               $x_count  = @et.text.toString.to_i
               @err.text = ""
               context.start_ruboto_activity ("GrafCanvas")
            else
               @err.text = "You are out of borders!"
               return
            end
         end

      end
   end
end

MainWindow.StartProject($irb)