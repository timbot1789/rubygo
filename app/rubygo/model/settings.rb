
class Rubygo
  module Model
    class Settings 
      
      attr_accessor :num_rows, :num_cols, :board_scale
      
      def initialize
        @num_rows = 12
        @num_cols = 12
        @board_scale = 60 
      end
      
      def text_index=(new_text_index)
        self.text = GREETINGS[new_text_index]
      end
      
      def text_index
        GREETINGS.index(text)
      end
    end
  end
end
