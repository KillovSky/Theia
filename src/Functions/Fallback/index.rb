# frozen_string_literal: true

##
# Módulo Fallback - Fornece comportamento padrão para funções não implementadas
module Functions
  module Fallback
    class << self
      ##
      # Método principal para tratamento de fallback
      #
      # @param data [Hash] Dados da requisição
      # @return [Hash] Resposta padrão
      def main(data)
        build_response(data)
      end

      private

      ##
      # Constrói resposta de fallback
      #
      # @param data [Hash] Dados da requisição
      # @return [Hash] Resposta formatada
      def build_response(data)
        {
          status: :error,
          message: "Function not implemented",
          requested: data['command'] || data['action'],
          timestamp: Time.now
        }
      end
    end
  end
end