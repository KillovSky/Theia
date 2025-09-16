# frozen_string_literal: true

##
# Módulo Commands::Cases - Manipulador de Comandos Simples
#
# Fornece uma maneira fácil para iniciantes adicionarem novos comandos
# usando um estilo limpo baseado em switch-case.
#
# Example:
#   Commands::Cases.main(command: 'test', chatId: 123)
#
module Commands
  module Cases
    ##
    # Configuração de comandos - Edite aqui para adicionar novos comandos!
    #
    # Estrutura:
    #   'nome_do_comando' => {
    #     admin_only: Boolean,  # Se apenas administradores podem usar
    #     response: Hash/Proc   # Resposta fixa ou lambda dinâmica
    #   }
    #
    # Tipos de resposta suportados:
    #   - Hash com :text, :audio, :video, etc.
    #   - Lambda que recebe env e retorna um Hash
    #
    COMMANDS = {   
      ##
      # Comando de informações sobre Ruby
      # Retorna detalhes do ambiente Ruby atual
      #
      # Uso: /rubyinfo
      'rubyinfo' => {
        response: lambda { |env|
          { 
            text: <<~INFO
              💎 Informações do Ambiente Ruby:
              Versão: #{RUBY_VERSION}
              Plataforma: #{RUBY_PLATFORM}
              Gems: #{Gem::Specification.count}
            INFO
          }
        }
      },
      
      ##
      # Comando de avaliação Ruby (apenas admin)
      # Executa código Ruby e retorna o resultado
      #
      # Uso: /evalrb <código>
      # Requer: env['arg'] contendo o código a ser avaliado
      'evalruby' => {
        admin_only: true,
        response: lambda { |env|
          { 
            text: "✅ Resultado:\n#{eval(env['arg'])}"  # rubocop:disable Security/Eval
          }
        }
      }
    }.freeze

    class << self
      ##
      # Ponto de entrada principal - processa todos os comandos
      #
      # @param env [Hash] Ambiente da mensagem recebida contendo:
      #   - :command [String] O comando a ser executado
      #   - :chatId [Integer] ID do chat para resposta
      #   - :isOwner [Boolean] Se o usuário é administrador
      #   - :reply [Hash] Mensagem para responder (opcional)
      #   - :arg [String] Argumentos adicionais (opcional)
      # @return [void]
      #
      # @raise [StandardError] Captura e loga erros durante o processamento
      def main(env)
        return unless env.is_a?(Hash)
        command = extract_command(env)
        return if command.empty?
        handle_command(command, env)
      rescue => e
        error_response(e, env)
      end

      private

      ##
      # Extrai o comando do ambiente
      #
      # @param env [Hash] Ambiente da mensagem
      # @return [String] Comando normalizado (downcase e strip)
      def extract_command(env)
        (env['command'] || env['body'] || '').downcase.strip
      end

      ##
      # Manipula o comando usando lógica de correspondência
      #
      # Primeiro verifica correspondências exatas, depois parciais
      # Finalmente verifica configuração de fallback
      #
      # @param command [String] Comando a ser processado
      # @param env [Hash] Ambiente da mensagem
      # @return [void]
      def handle_command(command, env)
        if handle_exact_match(command, env) || 
           handle_partial_match(command, env)
          return
        end
        handle_fallback(env)
      end

      ##
      # Processa correspondência exata de comandos
      #
      # @param command [String] Comando a verificar
      # @param env [Hash] Ambiente da mensagem
      # @return [Boolean] true se encontrou e processou comando
      def handle_exact_match(command, env)
        return false unless COMMANDS.key?(command)
        cmd_config = COMMANDS[command]
        return false unless check_permissions(cmd_config, env)
        response = build_response(cmd_config, env)
        send_response(env, response)
        true
      end

      ##
      # Processa correspondência parcial de comandos
      #
      # @param command [String] Comando a verificar
      # @param env [Hash] Ambiente da mensagem
      # @return [Boolean] true se encontrou e processou comando
      def handle_partial_match(command, env)
        COMMANDS.each do |cmd_name, config|
          if command.include?(cmd_name)
            return false unless check_permissions(config, env)
            response = build_response(config, env)
            send_response(env, response)
            return true
          end
        end
        false
      end

      ##
      # Processa fallback para comando desconhecido
      #
      # @param env [Hash] Ambiente da mensagem
      # @return [void]
      def handle_fallback(env)
        @config = Settings.load
        return unless @config['Cases']['value']
        send_response(env, { text: 'Comando não encontrado' }, raw: true)
      end

      ##
      # Verifica se o usuário tem permissão para executar o comando
      #
      # @param config [Hash] Configuração do comando
      # @param env [Hash] Ambiente da mensagem
      # @return [Boolean] true se tiver permissão
      def check_permissions(config, env)
        return true unless config[:admin_only]
        env.fetch('isOwner', false)
      end

      ##
      # Constrói a resposta apropriada
      #
      # @param config [Hash] Configuração do comando
      #   - :response [Hash/Proc] Resposta fixa ou lambda dinâmica
      # @param env [Hash] Ambiente da mensagem
      # @return [Hash] Resposta formatada
      def build_response(config, env)
        response = config[:response]
        response.is_a?(Proc) ? response.call(env) : response
      end

      ##
      # Envia a resposta (lida com qualquer tipo de mensagem)
      #
      # @param env [Hash] Ambiente da mensagem contendo:
      #   - :chatId [Integer] ID do chat de destino
      #   - :reply [Hash] Mensagem para citar (opcional)
      # @param content [Hash] Conteúdo da resposta
      # @param raw [Boolean] Se deve enviar raw diretamente
      # @return [void]
      def send_response(env, content, raw: false)
        params = {
          chatId: env['chatId'],
          message: content,
          quoted: env['reply']
        }.compact
        
        raw ? Functions::Message.send_raw(params) : Functions::Message.send(params)
      end

      ##
      # Manipula erros e envia mensagem de erro
      #
      # @param error [Exception] Erro ocorrido
      # @param env [Hash] Ambiente da mensagem
      # @return [void]
      def error_response(error, env)
        puts "[ERRO] #{Time.now} - #{error.message}"
        error.backtrace&.each { |line| puts line }
      end
    end
  end
end