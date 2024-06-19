Cell = Struct.new(:player, :row, :column, :dead)

class Rubygo
  module Model
    class Game
      attr_accessor :height, :width, :scale, :tokens, :cur_player, :game_over, :komi, :white_captures, :black_captures

      def initialize(height = 19, width = 19, scale = 85, white_score = 0, black_score = 0)
        @height = height
        @width = width
        @game_over = false
        @scale = scale - width - height
        @white_captures = white_score
        @black_captures = black_score
        @history = []
        @tokens = @height.times.map do |row|
          @width.times.map do |column|
            Cell.new(0, row, column)
          end
        end
        @cur_player = -1
      end

      def pass
        has_passed = ((@history.count > 0) && (@history.last[:action] == :pass))
        turn = {
          player: cur_player,
          action: :pass
        }
        @history.push turn
        return self.game_over = true if has_passed

        self.cur_player = -cur_player
      end

      def reset
        self.game_over = false
        self.cur_player = -1
        @history = []
        tokens.each do |col|
          col.each { |cell| cell[:player] = 0 }
        end
      end

      def resume
        self.game_over = false
        @tokens.each do |col|
          col.each do |cell|
            cell.dead = false
          end
        end

      end

      def find_group(group)
        cell = group.last
        return [] if cell.row > 0 && @tokens[cell.row - 1][cell.column].player.zero?
        return [] if cell.column > 0 && @tokens[cell.row][cell.column - 1].player.zero?
        return [] if cell.row < (@height - 1) && @tokens[cell.row + 1][cell.column].player.zero?
        return [] if cell.column < (@width - 1) && @tokens[cell.row][cell.column + 1].player.zero?

        row = cell.row
        col = cell.column
        player = cell.player
        if (row > 0) && (@tokens[row - 1][col].player == player) && (!group.include? @tokens[row - 1][col])
          up = find_group(group.push(@tokens[row - 1][col]))
          return [] if up.empty?
        end
        if (col > 0) && (@tokens[row][col - 1].player == player) && (!group.include? @tokens[row][col - 1])
          left = find_group(group.push(@tokens[row][col - 1]))
          return [] if left.empty?
        end
        if (row < (@height - 1)) && (@tokens[row + 1][col].player == player) && (!group.include? @tokens[row + 1][col])
          down = find_group(group.push(@tokens[row + 1][col]))
          return [] if down.empty?
        end
        if (col < (@width - 1)) && (@tokens[row][col + 1].player == player) && (!group.include? @tokens[row][col + 1])
          right = find_group(group.push(@tokens[row][col + 1]))
          return [] if right.empty?
        end
        group
      end

      def ko?
        return false if @history.count < 3

        now = @history.last
        last_real_turn = 2

        # Ignore history actions like :pass and :resign
        while @history[@history.count - last_real_turn][:action] != :play
          last_real_turn += 1
          return false if last_real_turn >= @history.count
        end
        last = @history[@history.count - last_real_turn]
        captures = last[:captures]
        (captures.count == 1) && (captures.first.row == now[:play].first) && (captures.first.column == now[:play].last)
      end

      def suicide?(cell)
        capture_group = find_group([cell])
        !capture_group.empty?
      end

      def revert_history(turns = 1)
        turns.times.each do
          history = @history.pop
          return unless history

          player = history[:player]
          self.cur_player = player
          next unless history[:action] == :play

          row, column = history[:play]
          tokens[row][column].player = 0
          history[:captures].each do |capture|
            tokens[capture.row][capture.column].player = -player
          end
          if player == 1
            self.white_captures -= history[:captures].count
          elsif player == -1
            self.black_captures -= history[:captures].count
          end
        end
      end

      def play(row, column)
        @has_passed = false
        token = tokens[row][column]
        return token.dead = !token.dead if game_over && token.player != 0
        return unless token.player.zero?

        token.player = cur_player
        captured = capture(token)
        turn = {
          player: cur_player,
          action: :play,
          play: [row, column],
          captures: captured.map(&:clone)
        }
        @history.push turn
        if cur_player == 1
          self.white_captures += captured.count
        elsif cur_player == -1
          self.black_captures += captured.count
        end

        return revert_history if suicide?(token) || ko?

        self.cur_player = -cur_player
      end

      def capture(cell)
        to_capture = []
        if cell.row > 0 && (@tokens[cell.row - 1][cell.column].player == -cell.player)
          to_capture.concat find_group([@tokens[cell.row - 1][cell.column]])
        end
        if (cell.column > 0) && (!to_capture.include? @tokens[cell.row][cell.column - 1]) && (@tokens[cell.row][cell.column - 1].player == -cell.player)
          to_capture.concat find_group([@tokens[cell.row][cell.column - 1]])
        end
        if (cell.row < (@height - 1)) && (!to_capture.include? @tokens[cell.row + 1][cell.column]) && (@tokens[cell.row + 1][cell.column].player == -cell.player)
          to_capture.concat find_group([@tokens[cell.row + 1][cell.column]])
        end
        if (cell.column < (@width - 1)) && (!to_capture.include? @tokens[cell.row][cell.column + 1]) && (@tokens[cell.row][cell.column + 1].player == -cell.player)
          to_capture.concat find_group([@tokens[cell.row][cell.column + 1]])
        end
        to_capture.each { |captured| captured.player = 0 }
        to_capture
      end

    end
  end
end
