Cell = Struct.new(:player, :row, :column, :dead, :border)
Score = Struct.new(:black, :white, :dame, :komi)

class Rubygo
  module Model
    class Game
      attr_accessor :height, :width, :tokens, :cur_player, :game_over, :komi, :white_score, :black_score, :handicap, :resigned

      def initialize(height = 19, width = 19, handicap = 0, komi = 0.5)
        @height = height
        @width = width
        @komi = komi
        @handicap = handicap
        @game_over = false
        @white_score = 0 
        @black_score = 0 
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

      def reset(new_height = 0, new_width = 0)
        self.height = new_height.positive? ? new_height : @height
        self.width = new_width.positive? ? new_width : @width
        self.game_over = false
        self.cur_player = -1
        self.white_score = 0
        self.black_score = 0
        @history = []
        @tokens = @height.times.map do |row|
          @width.times.map do |column|
            Cell.new(0, row, column)
          end
        end
      end

      def resume
        self.game_over = false
        self.resigned = nil
        @tokens.each do |col|
          col.each do |cell|
            if cell.dead
              self.white_score += 1 if cell.player == 1
              self.black_score += 1 if cell.player == -1
            end
            cell.dead = false
          end
        end
      end

      def resign
        self.resigned = self.cur_player
        self.game_over = true
      end

      def find_score_group(group)
        cell = group.last
        player = cell.player
        row = cell.row
        col = cell.column
        borders = []

        # Check own borders
        borders.push @tokens[row - 1][col].player if row.positive? && !@tokens[row - 1][col].player.zero? && !@tokens[row - 1][col].dead
        borders.push @tokens[row][col - 1].player if col.positive? && !@tokens[row][col - 1].player.zero? && !@tokens[row][col - 1].dead
        borders.push @tokens[row + 1][col].player if row < (@height - 1) && !@tokens[row + 1][col].player.zero? && !@tokens[row + 1][col].dead
        borders.push @tokens[row][col + 1].player if col < (@width - 1) && !@tokens[row][col + 1].player.zero? && !@tokens[row][col + 1].dead
        cell.border = borders.reduce(0) do |left, right|
          if (left == right) || left.zero?
            right
          elsif right.zero?
            left
          else
            2 # dame
          end
        end

        # Check group borders
        if row.positive? && ((@tokens[row - 1][col].player == player) || @tokens[row - 1][col].dead) && (!group.include? @tokens[row - 1][col])
          find_score_group(group.push(@tokens[row - 1][col]))
        end
        if col.positive? && ((@tokens[row][col - 1].player == player) || @tokens[row][col - 1].dead) && (!group.include? @tokens[row][col - 1])
          find_score_group(group.push(@tokens[row][col - 1]))
        end
        if (row < (@height - 1)) && ((@tokens[row + 1][col].player == player) || @tokens[row + 1][col].dead) && (!group.include? @tokens[row + 1][col])
          find_score_group(group.push(@tokens[row + 1][col]))
        end
        if (col < (@width - 1)) && ((@tokens[row][col + 1].player == player) || @tokens[row][col + 1].dead) && (!group.include? @tokens[row][col + 1])
          find_score_group(group.push(@tokens[row][col + 1]))
        end

        group
      end

      def calc_score
        seen = []
        black_points = @black_score
        white_points = @white_score
        dame_points = 0
        @tokens.each do |row|
          row.each do |cell|
            next if (cell.player != 0) || seen.include?(cell)

            score_group = find_score_group([cell])
            seen.concat score_group
            owner = score_group.reduce(0) do |left, right|
              if (left == right.border) || left.zero?
                right.border
              elsif right.border.zero?
                left
              else
                2 # dame
              end
            end
            black_points += score_group.count if owner == -1
            white_points += score_group.count if owner == 1
            dame_points += score_group.count if owner == 2
          end
        end
        Score.new(black_points, white_points, dame_points, @komi)
      end

      def find_liberty(group)
        cell = group.last
        player = cell.player
        row = cell.row
        col = cell.column

        # Check own liberties
        return [] if row.positive? && @tokens[row - 1][col].player.zero?
        return [] if col.positive? && @tokens[row][col - 1].player.zero?
        return [] if row < (@height - 1) && @tokens[row + 1][col].player.zero?
        return [] if col < (@width - 1) && @tokens[row][col + 1].player.zero?

        # Check group liberties
        if row.positive? && (@tokens[row - 1][col].player == player) && (!group.include? @tokens[row - 1][col])
          up = find_liberty(group.push(@tokens[row - 1][col]))
          return [] if up.empty?
        end
        if col.positive? && (@tokens[row][col - 1].player == player) && (!group.include? @tokens[row][col - 1])
          left = find_liberty(group.push(@tokens[row][col - 1]))
          return [] if left.empty?
        end
        if (row < (@height - 1)) && (@tokens[row + 1][col].player == player) && (!group.include? @tokens[row + 1][col])
          down = find_liberty(group.push(@tokens[row + 1][col]))
          return [] if down.empty?
        end
        if (col < (@width - 1)) && (@tokens[row][col + 1].player == player) && (!group.include? @tokens[row][col + 1])
          right = find_liberty(group.push(@tokens[row][col + 1]))
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
        !find_liberty([cell]).empty?
      end

      def revert_history(turns = 1)
        turns.times.each do
          history = @history.pop
          return unless history

          player = history[:player]
          self.cur_player = player
          next unless history[:action] == :play || history[:action] == :handicap
          self.handicap += 1 if history[:action] == :handicap

          row, column = history[:play]
          tokens[row][column].player = 0
          history[:captures].each do |capture|
            tokens[capture.row][capture.column].player = -player
          end
          if player == 1
            self.black_score += history[:captures].count
            self.white_score -= 1
          elsif player == -1
            self.white_score += history[:captures].count
            self.black_score -= 1
          end
        end
      end

      def play(row, column)
        @has_passed = false
        token = tokens[row][column]
        return if resigned
        if game_over && token.player != 0
          self.white_score -= 1 if token.player == 1
          self.black_score -= 1 if token.player == -1
          return token.dead = !token.dead
        end
        return unless token.player.zero? && !game_over

        token.player = cur_player
        captured = capture(token)
        turn = {
          player: cur_player,
          action: self.handicap.positive? ? :handicap : :play,
          play: [row, column],
          captures: captured.map(&:clone)
        }
        @history.push turn
        if cur_player == 1
          self.black_score -= captured.count
          self.white_score += 1
        elsif cur_player == -1
          self.white_score -= captured.count
          self.black_score += 1
        end

        return revert_history if suicide?(token) || ko?
        return self.handicap -= 1 if self.handicap.positive?

        self.cur_player = -cur_player
      end

      def capture(cell)
        to_capture = []
        row = cell.row
        col = cell.column
        player = cell.player
        if row.positive? && (@tokens[row - 1][col].player == -player)
          to_capture.concat find_liberty([@tokens[row - 1][col]])
        end
        if col.positive? && (!to_capture.include? @tokens[row][col - 1]) && (@tokens[row][col - 1].player == -player)
          to_capture.concat find_liberty([@tokens[row][col - 1]])
        end
        if (row < (@height - 1)) && (!to_capture.include? @tokens[row + 1][col]) && (@tokens[row + 1][col].player == -player)
          to_capture.concat find_liberty([@tokens[row + 1][col]])
        end
        if (col < (@width - 1)) && (!to_capture.include? @tokens[row][col + 1]) && (@tokens[row][col + 1].player == -player)
          to_capture.concat find_liberty([@tokens[row][col + 1]])
        end
        to_capture.each { |captured| captured.player = 0 }
        to_capture
      end
    end
  end
end
