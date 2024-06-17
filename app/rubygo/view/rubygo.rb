Cell = Struct.new (:player)

class Rubygo
  module Model
    class Game 
      
      attr_accessor :height, :width, :scale, :name, :tokens, :cur_player
      
      def initialize(height = 19, width = 19, scale = 90, name = "Go Game")
        @height = height
        @width = width
        @scale = scale - width - height
        @tokens = height.times.map do
          width.times.map do
            Cell.new(0) 
          end
        end
        @cur_player = 1
      end

      def play(row, column)
        return unless @tokens[row][column][:player] == 0 
        @tokens[row][column][:player] = @cur_player
        @cur_player = -@cur_player
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
          # Replace example content below with your own custom window content
          width <= [@game, :width, on_read: -> (width) {width * @game.scale}] 
          height <= [@game, :height, on_read: -> (height) {height * @game.scale}]
          title 'Ruby Go'
          resizable false

          margined true

          label {
            text <= [@game, :name]
          }
          vertical_box {
            content(@game, :tokens) {
              game_board(game: @game)
            }
          }
        }
      }

      def display_about_dialog
        message = "Rubygo #{VERSION}\n\n#{LICENSE}"
        msg_box('About', message)
      end

      def display_new_game_dialog
      end
    end
  end
end
