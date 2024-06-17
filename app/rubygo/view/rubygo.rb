class Rubygo
  module Model
    class Game 
      
      attr_accessor :height, :width, :scale, :name
      
      def initialize(height = 12, width = 12, scale = 70, name = "Go Game")
        @height = height
        @width = width
        @scale = scale
        @name = name
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
                  }
                  line(half,row == 0 ? half : 0, half, row == (game.height - 1)? half : game.scale) {
                    stroke 0x000000
                  } 
                  line(column == 0 ? half : 0, half, column == (game.width - 1) ? half : game.scale, half){
                    stroke 0x000000
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
      
      before_body do
        @game = Model::Game.new
      end

      body {
        window { |new_game_window|
          title "New Game"
          margined true
          vertical_box {
            group("Game Size") {
              vertical_box {
                  horizontal_box {
                    label('Board Width')
                    spinbox(2, 20) {
                      value <=> [@game, :width]
                    }
                  }
                  horizontal_box {
                    label('Board Height')
                    spinbox(2, 20) {
                      value <=> [@game, :height]
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
                  on_create.call(@game)
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

      ## Add options like the following to configure CustomWindow by outside consumers
      #
      # options :title, :background_color
      # option :width, default: 320
      # option :height, default: 240

            ## Use before_body block to pre-initialize variables to use in body and
      #  to setup application menu
      #
      before_body do
        @game = Model::Game.new

        menu('Game') {
          menu_item('New Game') {
            on_clicked do
              on_create = lambda { |game| 
                @game.height = game.height
                @game.width = game.width
              }
              new_game_window(on_create: on_create).show
            end
          }
          menu_item('Edit Current Game')
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
            content(@game, :width) {
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
