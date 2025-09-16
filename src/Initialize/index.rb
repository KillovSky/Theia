# frozen_string_literal: true

require 'websocket-client-simple'
require 'base64'
require 'json'
require 'logger'
require 'openssl'
require 'async'

module Theia
  ##
  # Classe principal da aplicação Theia - Sistema de Gerenciamento de Conexões WebSocket
  #
  # Responsável por:
  # - Gerenciar conexões WebSocket com reconexão automática
  # - Processar mensagens recebidas via WebSocket
  # - Executar tarefas em background (como verificação de atualizações)
  # - Fornecer desligamento gracioso
  #
  # @example Inicialização básica
  #   app = Theia::Application.new
  #   app.run
  #
  # @example Configuração personalizada
  #   app = Theia::Application.new.tap do |a|
  #     a.logger.level = Logger::DEBUG
  #   end
  #   app.run
  class Application
    # Constantes para melhor legibilidade e manutenção
    MAX_RECONNECT_ATTEMPTS = 3
    DEFAULT_UPDATE_INTERVAL = 3600
    
    ##
    # Inicializa uma nova instância da aplicação Theia
    #
    # Configura os componentes básicos:
    # - Logger para registro de eventos
    # - Carregamento de configurações
    # - Tratadores de sinais para desligamento gracioso
    # - Contadores de reconexão
    #
    # @return [Theia::Application] Nova instância da aplicação
    def initialize
      @running = true                # Controle de estado da aplicação
      @reconnect_attempts = 0        # Contador de tentativas de reconexão
      @max_reconnect_attempts = MAX_RECONNECT_ATTEMPTS    # Limite máximo de tentativas
      @shutting_down = false         # Flag para desligamento controlado
      @websocket = nil               # Referência para a conexão WebSocket
      setup_logger
      load_configuration
      load_dependencies
      setup_signal_handlers
    end

    ##
    # Callback chamado quando a conexão WebSocket é aberta
    #
    # @return [void]
    # @note Reseta o contador de tentativas de reconexão
    def handle_connection_open
      @logger.info(@colorfy.format('Conexão WebSocket estabelecida!', :green))
      @reconnect_attempts = 0
    end

    ##
    # Callback chamado quando uma mensagem é recebida
    #
    # @param msg [WebSocket::Client::Simple::Message] A mensagem recebida
    # @return [void]
    #
    # @note O fluxo de processamento é:
    #   1. Parseia a mensagem JSON
    #   2. Exibe a mensagem do printer (se existir)
    #   3. Roteia para o handler apropriado
    def handle_incoming_message(msg)
      data = parse_message(msg.data)
      return unless data
      
      # Exibe a mensagem do printer apenas se existir e não estiver vazia
      printer_message = data['printerMessage']
      puts printer_message if printer_message && !printer_message.to_s.strip.empty?
      
      route_message(data)
    rescue => e
      @logger.error("Erro no processamento da mensagem: #{e.message}")
      @logger.debug(e.backtrace.join("\n")) if @logger.debug?
    end

    ##
    # Callback chamado quando a conexão é fechada
    #
    # @param code [Integer] Código de fechamento
    # @param reason [String] Motivo do fechamento
    # @return [void]
    #
    # @note Inicia tentativa de reconexão, exceto durante desligamento
    def handle_connection_close(code, reason)
      @logger.info("Conexão fechada (código #{code}): #{reason}")
      attempt_reconnection unless @shutting_down
    end

    ##
    # Callback chamado quando ocorre um erro na conexão
    #
    # @param error [Exception] O erro ocorrido
    # @return [void]
    #
    # @note Inicia tentativa de reconexão, exceto durante desligamento
    def handle_connection_error(error)
      @logger.error("Erro WebSocket: #{error.message}")
      @logger.debug(error.backtrace.join("\n")) if @logger.debug?
      attempt_reconnection unless @shutting_down
    end

    ##
    # Inicia a execução da aplicação
    #
    # Cria tasks assíncronas para:
    # 1. Manutenção da conexão WebSocket
    # 2. Verificação periódica de atualizações
    #
    # @return [void]
    def run
      Async do |task|
        task.async { connect_websocket }
        task.async { run_version_checker }
      end
    end

    private

    ##
    # Configura o sistema de logging da aplicação
    #
    # @return [Logger] Instância configurada do logger com:
    #   - Saída para STDOUT
    #   - Formato: [TIMESTAMP] [LEVEL] mensagem
    #   - Nível padrão: INFO
    def setup_logger
      @logger = Logger.new($stdout).tap do |log|
        log.level = Logger::INFO
        log.formatter = proc do |severity, datetime, _, msg|
          "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
        end
      end
    end

    ##
    # Carrega as configurações do sistema
    #
    # @raise [RuntimeError] Se ocorrer erro ao carregar configurações
    # @return [Hash] Configurações carregadas contendo:
    #   - WebSocket: URL do servidor
    #   - Auth: credenciais de autenticação
    #   - UpdateInterval: intervalo de verificação de atualizações
    def load_configuration
      @logger.info("Carregando configurações...")
      @config = Settings.load
      @config
    rescue => e
      @logger.error("Erro ao carregar configurações: #{e.message}")
      @logger.debug(e.backtrace.join("\n")) if @logger.debug?
      raise
    end

    ##
    # Carrega as dependências essenciais da aplicação
    #
    # @return [void]
    # @note Dependências carregadas:
    #   - Módulo de atualizações
    #   - Módulo de cores
    #   - Módulo de comandos
    #   - Módulo de fallback
    def load_dependencies
      # Verifica se as dependências já foram carregadas para evitar carregamento duplicado
      return if defined?(Functions::Colors) && defined?(Commands::Cases) && defined?(Functions::Fallback)
      
      require_relative '../Functions/Update/index'
      require_relative '../Functions/Colors/index'
      require_relative '../Commands/Cases/index'
      require_relative '../Functions/Fallback/index'
      @colorfy = Functions::Colors
    end

    ##
    # Configura tratadores de sinais para desligamento gracioso
    #
    # - INT (Ctrl+C): Encerramento imediato
    # - TERM: Encerramento normal
    #
    # @return [void]
    def setup_signal_handlers
      Signal.trap('INT') { emergency_shutdown }
      Signal.trap('TERM') { graceful_shutdown }
    end

    ##
    # Estabelece conexão WebSocket com o servidor
    #
    # Configura callbacks para:
    # - Abertura de conexão
    # - Recebimento de mensagens
    # - Fechamento de conexão
    # - Tratamento de erros
    #
    # @raise [StandardError] Se ocorrer erro na conexão
    # @return [void]
    def connect_websocket
      @logger.info("Iniciando conexão WebSocket...")
      @websocket = WebSocket::Client::Simple.connect(
        @config['WebSocket']['value'],
        headers: auth_headers,
        ssl_context: ssl_context
      )
      setup_websocket_callbacks
      maintain_connection
    rescue => e
      @logger.error("Erro na conexão WebSocket: #{e.message}")
      @logger.debug(e.backtrace.join("\n")) if @logger.debug?
      handle_connection_error(e)
    end

    ##
    # Configura os callbacks do WebSocket
    #
    # @return [void]
    # @note Callbacks configurados:
    #   - :open -> handle_connection_open
    #   - :message -> handle_incoming_message
    #   - :close -> handle_connection_close
    #   - :error -> handle_connection_error
    def setup_websocket_callbacks
      # Armazena referência a self para os callbacks
      app = self
      @websocket.on(:open) { app.handle_connection_open }
      @websocket.on(:message) { |msg| app.handle_incoming_message(msg) }
      @websocket.on(:close) { |c, r| app.handle_connection_close(c, r) }
      @websocket.on(:error) { |e| app.handle_connection_error(e) }
    end

    ##
    # Mantém a conexão ativa enquanto a aplicação estiver rodando
    #
    # @return [void]
    def maintain_connection
      while @running
        sleep 1
      end
    end

    ##
    # Tenta reconectar ao servidor WebSocket
    #
    # Utiliza backoff exponencial entre tentativas:
    # 1ª tentativa: 2 segundos
    # 2ª tentativa: 4 segundos
    # 3ª tentativa: 8 segundos
    #
    # @return [void]
    # @note Para tentativas após o máximo configurado, inicia desligamento gracioso
    def attempt_reconnection
      return if @shutting_down
      @reconnect_attempts += 1
      if @reconnect_attempts <= @max_reconnect_attempts
        delay = 2 ** @reconnect_attempts
        @logger.info("Tentativa #{@reconnect_attempts}/#{@max_reconnect_attempts} em #{delay}s...")
        sleep delay
        connect_websocket
      else
        @logger.fatal("Máximo de tentativas de reconexão alcançado")
        graceful_shutdown
      end
    end

    ##
    # Parseia mensagem JSON recebida
    #
    # @param message [String] Mensagem JSON
    # @return [Hash, nil] Dados parseados ou nil em caso de erro
    def parse_message(message)
      return nil if message.nil? || message.to_s.strip.empty?
      
      JSON.parse(message)
    rescue JSON::ParserError => e
      @logger.error("Falha ao parsear mensagem: #{e.message}")
      @logger.debug("Conteúdo da mensagem: #{message.inspect}") if @logger.debug?
      nil
    end

    ##
    # Roteia mensagem para o handler apropriado
    #
    # @param data [Hash] Dados da mensagem contendo:
    #   - isCmd [Boolean] Se é um comando
    #   - printerMessage [String] Mensagem para exibição
    #   - outros campos específicos do comando
    # @return [void]
    #
    # @note Usa Commands::Cases para comandos ou Functions::Fallback como padrão
    def route_message(data)
      handler = data['isCmd'] ? Commands::Cases : Functions::Fallback
      handler.main(data)
    rescue => e
      @logger.error("Falha no roteamento: #{e.message}")
      @logger.debug(e.backtrace.join("\n")) if @logger.debug?
      Functions::Fallback.main(data.merge('error' => e.message))
    end

    ##
    # Executa verificação periódica de atualizações
    #
    # @return [void]
    # @note Intervalo configurável via settings (padrão: 3600 segundos)
    def run_version_checker
      interval = @config.dig('UpdateInterval', 'value') || DEFAULT_UPDATE_INTERVAL
      loop do
        Functions::Update.checkupdates
        sleep interval
        break if @shutting_down
      end
    end

    ##
    # Cria headers de autenticação para o WebSocket
    #
    # @return [Hash] Headers de autenticação contendo:
    #   - Authorization: Basic Auth com credenciais codificadas em Base64
    def auth_headers
      auth_config = @config.dig('Auth', 'value')
      return {} unless auth_config && auth_config['username'] && auth_config['password']
      
      credentials = "#{auth_config['username']}:#{auth_config['password']}"
      { 'Authorization' => "Basic #{Base64.strict_encode64(credentials)}" }
    end

    ##
    # Configura contexto SSL para conexão segura
    #
    # @return [OpenSSL::SSL::SSLContext] Contexto SSL configurado com:
    #   - Verificação SSL desabilitada (VERIFY_NONE)
    def ssl_context
      OpenSSL::SSL::SSLContext.new.tap do |ctx|
        ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    ##
    # Desligamento de emergência (Ctrl+C)
    #
    # @return [void]
    # @note Fecha a conexão WebSocket e termina o processo imediatamente
    def emergency_shutdown
      @shutting_down = true
      @running = false
      @websocket&.close
      puts "\nDesligamento emergencial iniciado..."
      exit
    end

    ##
    # Desligamento gracioso
    #
    # @return [void]
    # @note Fecha a conexão WebSocket e termina o processo normalmente
    def graceful_shutdown
      @shutting_down = true
      @running = false
      @websocket&.close
      @logger.info("Desligamento gracioso iniciado...")
      exit
    end
  end
end