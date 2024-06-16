require 'rubygo/model/greeting'

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
        @greeting = Model::Greeting.new

        menu('File') {
          menu_item('Preferences...') {
            on_clicked do
              display_preferences_dialog
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

      ## Use after_body block to setup observers for controls in body
      #
      # after_body do
      #
      # end

      ## Add control content inside custom window body
      ## Top-most control must be a window or another custom window
      #
      body {
        window {
          # Replace example content below with your own custom window content
          content_size 8*80, 8*80
          title 'RubyGo'
          resizable false

          margined true

          label {
            text <= [@greeting, :text]
          }
          vertical_box {
            padded false
            8.times.map do |row|
              horizontal_box {
                padded false

                8.times.map do |column|
                  area {
                    square(0, 0, 80) {
                      fill r: 240, g: 215, b: 141, a: 1.0
                    }
                    line(40,row == 0 ? 40 : 0, 40, row == 7 ? 40 : 80) {
                      stroke 0x000000
                    } 
                    line(column == 0 ? 40 : 0,40, column == 7 ? 40 : 80, 40){
                      stroke 0x000000
                    } 
                  }
                end
              }
            end
          }
        }
      }

      def display_about_dialog
        message = "Rubygo #{VERSION}\n\n#{LICENSE}"
        msg_box('About', message)
      end

      def display_preferences_dialog
        window {
          title 'Preferences'
          content_size 200, 100

          margined true

          vertical_box {
            padded true

            label('Greeting:') {
              stretchy false
            }

            radio_buttons {
              stretchy false

              items Model::Greeting::GREETINGS
              selected <=> [@greeting, :text_index]
            }
          }
        }.show
      end
    end
  end
end
