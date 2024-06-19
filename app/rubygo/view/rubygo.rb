require_relative '../model/game'

class Rubygo
  module View
    class GameBoard
      include Glimmer::LibUI::CustomControl
      option :game
      option :scale

      body {
        vertical_box {
          padded false
          game.height.times.map do |row|
            horizontal_box {
              padded false
              game.width.times.map do |column|
                third = scale / 3
                area {
                  on_mouse_up { game.play(row, column) }
                  content(game.tokens[row][column], :player) {
                    token = game.tokens[row][column]
                    square(0, 0, scale) {
                      fill r: 240, g: 215, b: 141, a: 1.0
                    }
                    if (row % 3).zero? && (column % 3).zero? && row.odd? && column.odd?
                      circle(third, third, 4) { fill :black }
                    end
                    line(third, row.zero? ? third : 0, third, row == (game.height - 1) ? third : scale) {
                      stroke 0x000000
                    }
                    line(column.zero? ? third : 0, third, column == (game.width - 1) ? third : scale, third) {
                      stroke 0x000000
                    }
                    if token.player == 1
                      circle(third, third, third) {
                        fill :white
                      }
                    elsif token.player == -1
                      circle(third, third, third) {
                        fill :black
                      }
                    end
                    line(0, 0, scale, scale) {
                      stroke <= [game.tokens[row][column], :dead, on_read: ->(dead) { dead ? :red : nil }]
                    }
                    line(0, scale, scale, 0) {
                      stroke <= [game.tokens[row][column], :dead, on_read: ->(dead) { dead ? :red : nil }]
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
      option :on_create, default: lambda { |game| }
      option :height, default: 12
      option :width, default: 12

      body {
        window { |new_game_window|
          title 'New Game'
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
                  on_create.call(height, width)
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
      option :get_score, default: lambda {}
      option :resume, default: lambda {}
      option :score

      body {
        window { |game_over_window|
          title "Game Over"
          margined true
          vertical_box {
            content(self, :score) {
              if self.score
                vertical_box {
                  label("Final Scores:")
                  label {
                    text <= [self[:score], :black, on_read: ->(score){ "Black Territory: #{score}" }]
                  }
                  label {
                    text <= [self[:score], :white, on_read: ->(score){ "White Territory: #{score}" }]
                  }
                  label {
                    text <= [self[:score], :dame, on_read: ->(score){ "Dame(Contested) Territory: #{score}" }]
                  }
                  label("Winner: #{self[:score].black > self[:score].white ? 'Black!' : 'White!'}")
                }
              else
                label("Game Over. Mark dead stones")
                button("Score Game") {
                  on_clicked do
                    self.score = get_score.call
                  end
                }
                button("Resume Game") {
                  on_clicked do
                    resume.call
                    game_over_window.destroy
                  end
                }
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
      option :game

      before_body do
        self.game = Model::Game.new
        @scale = 50
        @min_width = 450
        @min_height = 450

        menu('Game') {
          menu_item('New Game') {
            on_clicked do
              on_create = lambda { |height, width|
                self.game = Model::Game.new(height, width)
              }
              new_game_window(on_create: on_create, height: game.height, width: game.width).show
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
      end

      body {
        window {
          width <= [self, :game, on_read: ->(game_w) { (game_w.width * @scale) > @min_width ? (game_w.width * @scale) : @min_width }]
          height <= [self, :game, on_read: ->(game_h) { (game_h.height * @scale) > @min_height ?  (game_h.height * @scale) : @min_height}]
          title 'Ruby Go'
          resizable false

          margined true
          vertical_box {
            content(self, :game) {
              observe(game, :game_over) do |game_over|
                score = lambda {
                  game.calc_score
                }
                resume = lambda {
                  game.resume
                }
                game_over_window(get_score: score, resume: resume).show if game_over
              end
              horizontal_box {
                stretchy false
                vertical_box {
                  stretchy false
                  label {
                    text <= [game, :black_score, on_read: -> (val) { "Black Score: #{val}" }]
                  }
                  label{
                    text <= [game, :white_score, on_read: -> (val) { "White Score: #{val}" }]
                  }
                }
                label {}
                vertical_box{
                  stretchy false
                  label {
                    text <= [game, :cur_player, on_read: -> (player) { "Current Player: #{player == 1 ? "White" : "Black"}" }]
                  }
                  button('Pass Turn') {
                    on_clicked do
                      game.pass
                    end
                  }
                }
                label {}
                vertical_box {
                  stretchy false
                  button('Undo turn') {
                    on_clicked do
                      game.revert_history
                    end
                  }
                  button('Resign') {
                  }
                }
              }
              vertical_box {
                game_board(game: game, scale: (game.height * @scale > @min_height ? @scale : (@min_height / game.height)))
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
