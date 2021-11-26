#
# # Core
#
# Generic editor functionality that only depends on `Buffer`, `Cursor`
# and bare minimum of `View`
#
# Functionality that goes here should *only* be "objective" behaviours.
# E.g. what it means to move a cursor to the right is mostly objective.
# What should happen on enter probably isn't (may or may not include
# indenting the next line, may or may not involve stripping trailing
# whitespace, etc.). Methods for the objective, constituent parts of
# subjective/opinionated operations *can* be added here (e.g. an "enter"
# method which defers the subjective parts to a block or some hook
# mechanism could.
#
# Knows nothing of configuration or "fancier" options, which should
# generally be handled in a subclass
#
# `@view` must support `#top`/`#top=` and `#height` to control the
# viewable portion.
#
module EditorCore
  class Core
    attr_accessor :cursor, :buffer, :view

    # ## Basic cursor movement ##

    def move(row, col); @cursor = cursor.move(buffer, row.to_i, col.to_i) end
    def right(off=1);   @cursor = cursor.right(buffer,off.to_i) end
    def left(off=1);    @cursor = cursor.left(buffer,off.to_i) end
    def up(off=1);      @cursor = cursor.up(buffer,off.to_i) end
    def down(off=1);    @cursor = cursor.down(buffer,off.to_i) end

    def line_home;      @cursor = cursor.line_home end
    def line_end;       @cursor = cursor.line_end(buffer) end

    # ## Querying ##

    def current_line
      @buffer.lines(cursor.row)
    end

    def get_after
      @buffer.lines(cursor.row)[@cursor.col..-1]
    end

    ### View-relative cursor movement ##

    def buffer_home
      view_home
      @cursor = cursor.move(buffer, 0, cursor.col)
    end

    def buffer_end
      view_end
      @cursor = cursor.move(buffer, buffer.lines_count, cursor.col)
    end

    def page_down
      lines = view_down(view.height-1)
      @cursor = cursor.down(buffer, lines)
    end

    def page_up
      @cursor = cursor.up(buffer, view_up(view.height-1))
    end

    # View movement
    def view_up(offset = 1)
      oldtop = view.top
      view.top -= offset
      view.top = 0 if view.top < 0
      oldtop - view.top
    end

    def view_down(offset = 1)
      oldtop = view.top
      view.top += offset
      if view.top > buffer.lines_count
        view.top = buffer.lines_count
      end
      view.top - oldtop
    end

    def view_home
      view.top = 0
    end

    def view_end
      view.top = buffer.lines_count - view.height
    end

    # ## Complex navigation ##
    def next_word
      line = current_line
      c = cursor.col
      m = line.length
      while c<m && line[c]&.match(/[^a-zA-Z]/)
        c += 1
      end
      if c >= m
        # FIXME: Pathological cases can cause stack issue here.
        @cursor = Cursor.new(cursor.row,m)
        right
        return next_word
      end

      if run = line[c..-1]&.match(/([a-zA-Z]+)/)
        c += run[0].length
        #pry([line,c,run])
      end
      off = c - cursor.col
      right(off)
      off
    end


    def prev_word
      return if cursor.col == 0
      line = current_line
      c = cursor.col
      if c > 0
        c -= 1
      end
      while c > 0 && line[c] && line[c].match(/[ \t]/)
        c -= 1
      end
      while c > 0 && !(line[c-1].match(/[ \t\-]/))
        c -= 1
      end
      off = cursor.col - c
      @cursor = Cursor.new(cursor.row, c)
      off
    end

    # ## Mutation ##

    def delete_before
      buffer.delete(cursor, 0, cursor.col)
      line_home
    end

    def delete_after
      buffer.delete(cursor, cursor.col,-1)
    end

    def delete
      return if cursor.end_of_file?(buffer)

      if cursor.end_of_line?(buffer)
        buffer.join_lines(cursor)
      else
        buffer.delete(cursor, cursor.col)
      end
    end

    def join_line
      buffer.join_lines(cursor)
    end

    def backspace
      return if cursor.beginning_of_file?

      if cursor.col == 0
        cursor_left = buffer.lines(cursor.row).size + 1
        buffer.join_lines(cursor,-1)
        cursor_left.times { left }
      else
        buffer.delete(cursor, cursor.col - 1)
        left
      end
    end


    def rstrip_line
      line = current_line
      stripped = current_line.rstrip
      return if line.length == stripped.length
      col = cursor.col
      oldc = cursor
      move(cursor.row, stripped.length)
      delete_after
      if col < stripped.length
        @cursor = oldc
      end
    end

  end
end
