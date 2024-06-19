Cell = Struct.new(:player, :row, :column, :dead)

class Rubygo
  module Model
    class Game 
      
      attr_accessor :height, :width, :scale, :name, :tokens, :cur_player, :game_over, :komi, :white_captures, :black_captures
      
      def initialize(height = 19, width = 19, scale = 85, name = "Go Game", white_score = 0, black_score = 0)
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

        self.cur_player = -self.cur_player
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
        game_over = false
        @tokens.each do |col|
          col.each do |cell|
            cell.dead = false
          end
        end

      end

      def find_group(group)
        cell = group.last
        return [] if cell.row > 0 && @tokens[cell.row - 1][cell.column].player == 0 
        return [] if cell.column > 0 && @tokens[cell.row][cell.column - 1].player == 0 
        return [] if cell.row < (@height - 1) && @tokens[cell.row + 1][cell.column].player == 0 
        return [] if cell.column < (@width - 1) && @tokens[cell.row][cell.column + 1].player == 0 

        if (cell.row > 0) && (@tokens[cell.row - 1][cell.column].player == cell.player) && (!group.include? @tokens[cell.row - 1][cell.column])
          up = find_group(group.push(@tokens[cell.row - 1][cell.column]))
          return [] if up.empty?
        end
        if (cell.column > 0) && (@tokens[cell.row][cell.column - 1].player == cell.player) && (!group.include? @tokens[cell.row][cell.column - 1])
          left = find_group(group.push(@tokens[cell.row][cell.column - 1]))
          return [] if left.empty?
        end
        if (cell.row < (@height - 1)) && (@tokens[cell.row + 1][cell.column].player == cell.player) && (!group.include? @tokens[cell.row + 1][cell.column])
          down = find_group(group.push(@tokens[cell.row + 1][cell.column]))
          return [] if down.empty?
        end
        if (cell.column < (@width - 1)) && (@tokens[cell.row][cell.column + 1].player == cell.player) && (!group.include? @tokens[cell.row][cell.column + 1])
          right = find_group(group.push(@tokens[cell.row][cell.column + 1]))
          return [] if right.empty?
        end
        group
      end

      def is_ko? 
        return false if @history.count < 3
        now = @history.last
        last_real_turn = 2

        # Ignore history actions like :pass and :resign
        while @history[@history.count - last_real_turn][:action] != :play
          last_real_turn += 1
        end
        last = @history[@history.count - last_real_turn] 
        if (last[:captures].count == 1) && (last[:captures].first.row == now[:play].first) && (last[:captures].first.column == now[:play].last)
          return true
        end
        false
      end 

      def is_suicide?(cell)
        capture_group = self.find_group([cell])
        return !capture_group.empty?
      end

      def revert_history(turns = 1)
        turns.times.each do
          history = @history.pop
          return unless history 
          player = history[:player]
          self.cur_player = player
          if history[:action] == :play 
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
      end

      def play(row, column)
        @has_passed = false
        token = tokens[row][column]
        if self.game_over && token.player != 0
          return token.dead = !token.dead
        end
        return unless token.player == 0
        token.player = cur_player
        captured = self.capture(token)
        turn = {
          player: cur_player,
          action: :play, 
          play: [row, column],
          captures: captured.map{ |capture| capture.clone }
        }
        @history.push turn 
        if cur_player == 1
          self.white_captures += captured.count
        elsif cur_player == -1
          self.black_captures += captured.count
        end

        return revert_history if is_suicide?(token)

        return revert_history if is_ko?

        self.cur_player = -self.cur_player
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
        to_capture.each {|cell| cell.player = 0}
        to_capture
      end

    end
  end
end

class Rubygo
  module View
    class GameBoard
      include Glimmer::LibUI::CustomControl
      option :game

      body{
        vertical_box {
          padded false
          game.height.times.map do |row|
            horizontal_box {
              padded false
              game.width.times.map do |column|
                half = game.scale / 2
                area {
                  on_mouse_up { game.play(row, column) }
                  content(game.tokens[row][column], :player) {
                    token = game.tokens[row][column]
                    square(0, 0, game.scale) {
                      fill r: 240, g: 215, b: 141, a: 1.0
                      
                    }
                    if (row % 3 == 0) && (column % 3 == 0) && (row % 2 != 0) && (column % 2 != 0) 
                      circle(half, half, 4) { fill :black }
                    end
                    line(half,row == 0 ? half : 0, half, row == (game.height - 1)? half : game.scale) {
                      stroke 0x000000
                    } 
                    line(column == 0 ? half : 0, half, column == (game.width - 1) ? half : game.scale, half){
                      stroke 0x000000
                    } 
                    if token.player == 1 
                      circle(half, half, half - 8) {
                        fill :white
                      }
                    elsif token.player == -1
                      circle(half, half, half - 8) {
                        fill :black
                      }
                    end
                    line(0, 0, game.scale, game.scale) {
                      stroke <= [game.tokens[row][column], :dead, on_read: ->  (dead) { dead ? :red : nil }]
                    }
                    line(0, game.scale, game.scale, 0) {
                      stroke <= [game.tokens[row][column], :dead, on_read: -> (dead) { dead ? :red : nil }] 
                    }
                  }
                }
              end
            }
          end
        }
      }
    end
  end
end

class Rubygo
  module View
    class NewGameWindow
      include Glimmer::LibUI::CustomWindow
      option :on_create, default: lambda { |user| }
      option :height, default: 12
      option :width, default: 12

      body {
        window { |new_game_window|
          title "New Game"
          margined true
          vertical_box {
            group("Game Size") {
              vertical_box {
                  horizontal_box {
                    label('Board Width')
                    spinbox(1, 20) {
                      value <=> [self, :width]
                    }
                  }
                  horizontal_box {
                    label('Board Height')
                    spinbox(1, 20) {
                      value <=> [self, :height]
                    }
                  }
              }
            }
            horizontal_box {
              stretchy false
              button("Cancel") {
                on_clicked do
                  new_game_window.destroy
                end
              }
              button("New Game") {
                on_clicked do
                  on_create.call(Model::Game.new(height, width))
                  new_game_window.destroy
                end
              }
            }
          }
        }
      }
    end
  end
end

class Rubygo
  module View
    class GameOverWindow
      include Glimmer::LibUI::CustomWindow
      option :restart, default: lambda {}
      option :resume, default: lambda {}
      
      body {
        window { |game_over_window|
          title "Game Over"
          margined true
          vertical_box {
            label("Game Over. Mark dead stones")
            button("Score Game") {
              on_clicked do
                restart.call()
                game_over_window.destroy
              end
            }
            button("Resume Game") {
              on_clicked do
                resume.call()
                game_over_window.destroy
              end
            }
          }
        }
      }
    end
  end
end

class Rubygo
  module View
    class Rubygo
      include Glimmer::LibUI::Application

      before_body do
        @game = Model::Game.new

        menu('Game') {
          menu_item('New Game') {
            on_clicked do
              on_create = lambda { |game| 
                @game.height = game.height
                @game.width = game.width
                @game.tokens = game.tokens
                @game.cur_player = -1
              }
              new_game_window(on_create: on_create, height: @game.height, width: @game.width).show
            end
          }

          # Enables quitting with CMD+Q on Mac with Mac Quit menu item
          quit_menu_item if OS.mac?
        }
        menu('Help') {
          if OS.mac?
            about_menu_item {
              on_clicked do
                display_about_dialog
              end
            }
          end

          menu_item('About') {
            on_clicked do
              display_about_dialog
            end
          }
        }
        observe(@game, :game_over) do |game_over|
          restart = lambda {
            @game.reset
          }
          resume = lambda {
            @game.resume
          }
          game_over_window(restart: restart, resume: resume).show if game_over
        end
      end

      body {
        window { 
          width <= [@game, :width, on_read: -> (width) {width * @game.scale}] 
          height <= [@game, :height, on_read: -> (height) {height * @game.scale}]
          title 'Ruby Go'
          resizable false

          margined true
          vertical_box {
            horizontal_box {
              stretchy false
              vertical_box {
                stretchy false
                label {
                  text <= [@game, :black_captures, on_read: -> (val) {"Black Captures: #{val}"}]
                }
                label{
                  text <= [@game, :white_captures, on_read: -> (val) {"White Captures: #{val}"}]
                }
              }
              label {}
              vertical_box{
                stretchy false
                label {
                  text <= [@game, :cur_player, on_read: -> (player) {"Current Player: #{player == 1 ? "White" : "Black"}"}]
                }
                button('Pass Turn') {
                  on_clicked do
                    @game.pass
                  end
                }
              }
              label {}
              vertical_box {
                stretchy false
                button('Undo turn') {
                  on_clicked do
                    @game.revert_history
                  end
                } 
                button('Resign') {
                } 
              }
            }
            vertical_box {
              content(@game, :tokens) {
                game_board(game: @game)
              }
            }
          }
        }
      }

      def display_about_dialog
        message = "Rubygo #{VERSION}\n\n#{LICENSE}"
        msg_box('About', message)
      end
    end
  end
end
