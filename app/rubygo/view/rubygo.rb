require_relative '../model/game'

class Rubygo
  module View
    class GameBoard
      include Glimmer::LibUI::CustomControl
      option :game
      option :scale

      body {
        row_center = game.height / 2
        col_center = game.height / 2
        row_dot_distance = game.height < 7 ? nil : (game.height < 13 ? 2 : 3)
        col_dot_distance = game.width < 7 ? nil : (game.width < 13 ? 2 : 3)
        vertical_box {
          padded false
          game.height.times.map do |row|
            horizontal_box {
              padded false
              game.width.times.map do |column|
                half = (scale / 2) - 1
                area {
                  on_mouse_up { game.play(row, column) }
                  content(game.tokens[row][column], :player) {
                    token = game.tokens[row][column]
                    square(0, 0, scale) {
                      fill r: 240, g: 215, b: 141, a: 1.0
                    }

                    # Dynamically set board dots
                    if ((game.height.odd? && row == row_center) && (game.width.odd? && column == col_center)) ||
                       (row == row_dot_distance && column == col_dot_distance) ||
                       (game.height > 13 && (column == col_dot_distance && row == row_center)) ||
                       (game.width > 13 && (row == row_dot_distance && column == col_center)) ||
                       (row_dot_distance && game.width > 13 && (row + row_dot_distance + 1 == game.height && column == col_center)) ||
                       (row_dot_distance && (row + row_dot_distance + 1) == game.height && column == col_dot_distance) ||
                       (col_dot_distance && game.height > 13 && (column + col_dot_distance + 1) == game.width && row == row_center) ||
                       (col_dot_distance && row_dot_distance && (column + col_dot_distance + 1) == game.width && row == row_dot_distance) ||
                       (col_dot_distance && row_dot_distance && (column + col_dot_distance + 1) == game.width && (row + row_dot_distance + 1) == game.height)
                      circle(half, half, 4) { fill :black }
                    end

                    # vertical line
                    line(half, (row.zero? ? half : 0), half, (row == (game.height - 1) ? half : scale)) {
                      stroke 0x000000
                    }

                    # horizontal line
                    line((column.zero? ? half : 0), half, (column == (game.width - 1) ? half : scale), half) {
                      stroke 0x000000
                    }
                    if token.player == 1
                      circle(half, half, (3 * half) / 4) {
                        fill :white
                      }
                    elsif token.player == -1
                      circle(half, half, (3 * half) / 4) {
                        fill :black
                      }
                    end
                    line(half - ((3 * half) / 4), half - ((3 * half) / 4), half + ((3 * half) / 4), half + ((3 * half) / 4)) {
                      stroke <= [game.tokens[row][column], :dead, on_read: ->(dead) { dead ? :red : nil }]
                    }
                    line(half - ((3 * half) / 4), half + ((3 * half) / 4), half + ((3 * half) / 4), half - ((3 * half) / 4)) {
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
      option :new_size, default: 19
      option :handicap, default: 0
      option :komi, default: "0.5"

      body {
        window { |new_game_window|
          title 'New Game'
          margined true
          vertical_box {
            group("Game Size") {
              vertical_box {
                horizontal_box {
                  label('Board Size')
                  spinbox(1, 20) {
                    value <=> [self, :new_size]
                  }
                }
                horizontal_box {
                  label {}
                }
              }
            }
            group("Handicaps") {
              margined true
              vertical_box {
                horizontal_box {
                  label('Black Handicap')
                  spinbox(0, 20) {
                    value <=> [self, :handicap]
                  }
                }
                horizontal_box {
                  label('Komi')
                  entry {
                    text <=> [self, :komi]
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
                  on_create.call(new_size, new_size, handicap, komi.to_f)
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
      option :restart, default: lambda {}
      option :score

      body {
        window { |game_over_window|
          title "Game Over"
          margined true
          vertical_box {
            content(self, :score) {
              if self.score
                vertical_box {
                  black = score.black
                  white = score.white + score.komi
                  winner = (black > white) ? 'Black ' + (black - white).to_s : (white > black) ? 'White ' + (white - black).to_s  : 'Tie!'
                  label("Final Scores")
                  label {
                    text <= [self.score, :black, on_read: ->(score){ "Black Territory: #{score}" }]
                  }
                  label {
                    text <= [self.score, :white, on_read: ->(score){ "White Territory: #{score}" }]
                  }
                  label {
                    text <= [self.score, :dame, on_read: ->(score){ "Dame(Contested) Territory: #{score}" }]
                  }
                  label {
                    text <= [self.score, :komi, on_read: ->(score){ "Komi: #{score}" }]
                  }
                  label("Winner: #{winner}")
                  button("New Game") {
                    on_clicked do
                      restart.call
                      game_over_window.destroy
                    end
                  }
                }
              else
                label("Game Over. Mark dead stones")
                button("Score Game") {
                  on_clicked { self.score = get_score.call }
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
    class ResignWindow 
      include Glimmer::LibUI::CustomWindow
      option :resignation
      option :resume, default: lambda {}
      option :restart, default: lambda {}

      body {
        window { |game_over_window|
          title "Game Over"
          margined true
          vertical_box {
            label("Game Over. #{resignation == 1 ? 'White' : 'Black'} resigned")
            button("New Game") {
              on_clicked do
                restart.call
                game_over_window.destroy
              end
            }
            button("Resume Game") {
              on_clicked do
                resume.call
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
      option :game

      before_body do
        self.game = Model::Game.new
        @scale = 45
        @min_width = 700
        @min_height = 750

        menu('Game') {
          menu_item('New Game') {
            on_clicked do
              on_create = lambda { |height, width, handicap, komi|
                self.game = Model::Game.new(height, width, handicap, komi)
              }
              new_game_window(on_create: on_create, new_height: game.height, new_width: game.width, handicap: game.handicap, komi: game.komi.to_s).show
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
                restart = lambda {
                  self.game = Model::Game.new(game.height, game.width, game.handicap, game.komi)
                }
                if game_over
                  if game.resigned
                    resign_window(resignation: game.resigned, restart: restart, resume: resume).show
                  else
                    game_over_window(get_score: score, resume: resume, restart: restart).show
                  end
                end
              end
              horizontal_box {
                stretchy false
                vertical_box {
                  stretchy false
                  label {
                    text <= [game, :black_score, on_read: -> (val) { "Black Score: #{val}" }]
                  }
                  label {
                    text <= [game, :white_score, on_read: -> (val) { "White Score: #{val}" }]
                  }
                }
                label {}
                vertical_box{
                  stretchy false
                  label {
                    text <= [game, :cur_player, on_read: -> (player) { "Current Player: #{player == 1 ? "White" : "Black"}" }]
                  }
                  label {
                    text <= [game, :handicap, on_read: -> (handicap) {handicap > 0 ? "Handicap: #{handicap}" : ""}]
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
                    on_clicked do
                      game.resign
                    end
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
