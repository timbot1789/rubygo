Cell = Struct.new(:player, :row, :column)

class Rubygo
  module Model
    class Game 
      
      attr_reader :white_score, :black_score
      attr_accessor :height, :width, :scale, :name, :tokens, :cur_player
      
      def initialize(height = 19, width = 19, scale = 80, name = "Go Game", white_score = 0, black_score = 0)
        @height = height
        @width = width
        @scale = scale - width - height
        @white_score = white_score
        @black_score = black_score 
        @tokens = @height.times.map do |row|
          @width.times.map do |column|
            Cell.new(0, row, column) 
          end
        end
        @cur_player = 1
      end

      def find_capture_group(group)
        cell = group.last
        return [] if cell.row > 0 && @tokens[cell.row - 1][cell.column].player == 0 
        return [] if cell.column > 0 && @tokens[cell.row][cell.column - 1].player == 0 
        return [] if cell.row < @height && @tokens[cell.row + 1][cell.column].player == 0 
        return [] if cell.column < @width && @tokens[cell.row][cell.column + 1].player == 0 

        if (cell.row > 0) && (@tokens[cell.row - 1][cell.column].player == cell.player) && (!group.include? @tokens[cell.row - 1][cell.column])
          up = find_capture_group(group.push(@tokens[cell.row - 1][cell.column]))
          return [] if up.empty?
        end
        if (cell.column > 0) && (@tokens[cell.row][cell.column - 1].player == cell.player) && (!group.include? @tokens[cell.row][cell.column - 1])
          left = find_capture_group(group.push(@tokens[cell.row][cell.column - 1]))
          return [] if left.empty?
        end
        if (cell.row < @height) && (@tokens[cell.row + 1][cell.column].player == cell.player) && (!group.include? @tokens[cell.row + 1][cell.column])
          down = find_capture_group(group.push(@tokens[cell.row + 1][cell.column]))
          return [] if down.empty?
        end
        if (cell.column < @width) && (@tokens[cell.row][cell.column + 1].player == cell.player) && (!group.include? @tokens[cell.row][cell.column + 1])
          right = find_capture_group(group.push(@tokens[cell.row][cell.column + 1]))
          return [] if right.empty?
        end
        group
      end

      def capture(cell)
        to_capture = []
        if cell.row > 0 && (@tokens[cell.row - 1][cell.column].player != cell.player)
          to_capture.concat find_capture_group([@tokens[cell.row - 1][cell.column]])
        end
        if (cell.column > 0) && (!to_capture.include? @tokens[cell.row][cell.column - 1]) && (@tokens[cell.row][cell.column - 1].player != cell.player)
          to_capture.concat find_capture_group([@tokens[cell.row][cell.column - 1]])
        end
        if (cell.row < @height) && (!to_capture.include? @tokens[cell.row + 1][cell.column]) && (@tokens[cell.row + 1][cell.column].player != cell.player)
          to_capture.concat find_capture_group([@tokens[cell.row + 1][cell.column]])
        end
        if (cell.column < @width) && (!to_capture.include? @tokens[cell.row][cell.column + 1]) && (@tokens[cell.row][cell.column + 1].player != cell.player)
          to_capture.concat find_capture_group([@tokens[cell.row][cell.column + 1]])
        end
        to_capture.each {|cell| cell.player = 0}

      end

      def play(row, column)
        return unless @tokens[row][column][:player] == 0
        @tokens[row][column][:player] = @cur_player
        cell = @tokens[row][column]
        capture(cell)
        capture_group = find_capture_group([cell])
        unless capture_group.empty?
          @tokens[row][column][:player] = 0
          return
        end
        self.cur_player = -@cur_player
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
                  square(0, 0, game.scale) {
                    fill r: 240, g: 215, b: 141, a: 1.0
                    on_mouse_up do |clicked_event|
                      game.play(row, column)
                    end
                  }
                  line(half,row == 0 ? half : 0, half, row == (game.height - 1)? half : game.scale) {
                    stroke 0x000000
                  } 
                  line(column == 0 ? half : 0, half, column == (game.width - 1) ? half : game.scale, half){
                    stroke 0x000000
                  } 
                  circle(half, half, half - 8) {
                    fill <= [game.tokens[row][column], :player, on_read: -> (player) { 
                      return if player == 0
                      return :white if player == 1
                      :black 
                    } ]
                    
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
                @game.cur_player = 1
              }
              new_game_window(on_create: on_create, height: @game.height, width: @game.width).show
            end
          }
          menu_item('Load Game')

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
              label {
                text <= [@game, :cur_player, on_read: -> (player) {"Current Player: #{player == 1 ? "White" : "Black"}"}]
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
