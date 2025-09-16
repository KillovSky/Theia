# frozen_string_literal: true

##
# Módulo principal de Comandos - Ponto de entrada para processamento de comandos
module Commands
  class << self
    ##
    # Processa um comando recebido
    #
    # @param env [Hash] Ambiente contendo informações do comando
    # @return [void]
    def main(env)
      Cases.main(env)
    end
  end
end