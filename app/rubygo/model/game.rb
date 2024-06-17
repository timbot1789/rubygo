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
