# frozen_string_literal: true

##
# Módulo Functions::Colors - Fornece formatação de texto com cores ANSI
#
# Este módulo permite formatar texto no terminal usando códigos ANSI para:
# - Cores de texto (16 cores disponíveis)
# - Cores de fundo (16 cores disponíveis)
# - Estilos de texto (negrito, itálico, sublinhado, etc.)
#
# Exemplos de uso:
#   puts Functions::Colors.format("Texto em vermelho", :red)
#   Functions::Colors.print("Alerta importante!", :bright_red, :bold)
#   puts Functions::Colors.blue("Texto azul")
#   puts Functions::Colors.bg_yellow("Fundo amarelo")
#
module Functions
  module Colors
    ##
    # Códigos ANSI para estilos de texto
    #
    # Mapeamento de símbolos para códigos ANSI:
    #   :reset, :bold, :dim, :italic, :underline, etc.
    STYLES = {
      reset: 0, bold: 1, dim: 2, italic: 3, underline: 4,
      blink: 5, inverse: 7, hidden: 8, strikethrough: 9
    }.freeze

    ##
    # Códigos ANSI para cores de texto (16 cores)
    #
    # Inclui cores normais e brilhantes:
    #   :black, :red, ..., :white, :bright_red, ..., :bright_white
    #   :gray é um alias para :grey
    COLORS = {
      black: 30, red: 31, green: 32, yellow: 33,
      blue: 34, magenta: 35, cyan: 36, white: 37,
      gray: 90, grey: 90, bright_red: 91, bright_green: 92,
      bright_yellow: 93, bright_blue: 94, bright_magenta: 95,
      bright_cyan: 96, bright_white: 97
    }.freeze

    ##
    # Códigos ANSI para cores de fundo (16 cores)
    #
    # Prefixo 'bg_' para cores de fundo:
    #   :bg_black, :bg_red, ..., :bg_bright_white
    #   :bg_gray é um alias para :bg_grey
    BACKGROUNDS = {
      bg_black: 40, bg_red: 41, bg_green: 42, bg_yellow: 43,
      bg_blue: 44, bg_magenta: 45, bg_cyan: 46, bg_white: 47,
      bg_gray: 100, bg_grey: 100, bg_bright_red: 101, bg_bright_green: 102,
      bg_bright_yellow: 103, bg_bright_blue: 104, bg_bright_magenta: 105,
      bg_bright_cyan: 106, bg_bright_white: 107
    }.freeze

    class << self
      ##
      # Formata texto com códigos ANSI
      #
      # @param text [String] Texto a ser formatado
      # @param styles [Array<Symbol>] Estilos, cores ou fundos a aplicar
      # @return [String] Texto formatado com códigos ANSI
      #
      # Exemplo:
      #   format("Alerta", :bright_red, :bold, :bg_white)
      def format(text, *styles)
        return text.to_s if styles.empty? || !text
        
        codes = styles.map { |s| STYLES[s] || COLORS[s] || BACKGROUNDS[s] }.compact
        return text.to_s if codes.empty?
        
        "\e[#{codes.join(';')}m#{text}\e[0m"
      end

      ##
      # Imprime texto formatado diretamente no output
      #
      # @param text [String] Texto a ser impresso
      # @param styles [Array<Symbol>] Estilos/cor a aplicar
      # @return [void]
      #
      # Exemplo:
      #   print("Sucesso!", :green, :bold)
      def print(text, *styles)
        puts format(text, *styles)
      end

      ##
      # Define métodos dinâmicos para cada cor de texto
      #
      # Cria métodos como:
      #   red(text), blue(text), bright_white(text), etc.
      COLORS.each_key do |color|
        define_method(color) { |text| format(text, color) }
      end

      ##
      # Define métodos dinâmicos para cada cor de fundo
      #
      # Cria métodos como:
      #   bg_red(text), bg_blue(text), bg_bright_white(text), etc.
      BACKGROUNDS.each_key do |bg|
        define_method(bg) { |text| format(text, bg) }
      end
    end
  end
end