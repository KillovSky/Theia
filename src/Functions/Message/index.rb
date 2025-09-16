# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'openssl'

module Functions
  ##
  # Módulo Functions::Message - Manipulador de Mensagens via API
  #
  # Fornece métodos para envio de mensagens através de requisições HTTP,
  # com tratamento de erros, retentativas e configuração flexível.
  #
  # Principais características:
  # - Suporte a mensagens padrão e raw
  # - Retentativas automáticas com backoff exponencial
  # - Timeout configurável
  # - Tratamento estruturado de erros
  # - Autenticação básica
  #
  # Exemplos de uso:
  #   Functions::Message.send(chatId: '123', message: 'Olá mundo!')
  #   Functions::Message.send_raw(chatId: '123', message: { text: 'Raw', buttons: [...] })
  #
  module Message
    class << self
      ##
      # Tempo máximo de espera para requisições (em segundos)
      DEFAULT_TIMEOUT = 60
      
      ##
      # Número máximo de tentativas de reenvio
      MAX_RETRIES = 3
      
      ##
      # Intervalos entre tentativas (em segundos) - backoff exponencial
      RETRY_DELAYS = [1, 2, 4].freeze

      ##
      # Envia uma mensagem padrão formatada automaticamente
      #
      # @param params [Hash] Parâmetros da mensagem contendo:
      #   @option params [String] :chatId (obrigatório) ID do chat destinatário
      #   @option params [Hash,String] :message (obrigatório) Conteúdo da mensagem
      #     - String: convertida para formato { text: "..." }
      #     - Hash: usado diretamente (ex: { text: "...", buttons: [...] })
      #   @option params [Boolean] :quoted (opcional) Se a mensagem é uma resposta
      # @return [Hash] Resposta da API contendo:
      #   - status: 'success' ou 'error'
      #   - data: conteúdo da resposta em caso de sucesso
      #   - error: mensagem de erro em caso de falha
      #
      # @raise [ArgumentError] Se parâmetros obrigatórios estiverem faltando
      def send(params)
        api_request(params)
      end

      ##
      # Envia uma mensagem no formato raw (sem formatação automática)
      #
      # @param params [Hash] Parâmetros da mensagem contendo:
      #   @option params [String] :chatId (obrigatório) ID do chat destinatário
      #   @option params [Hash] :message (obrigatório) Conteúdo da mensagem no formato raw
      #   @option params [Boolean] :quoted (opcional) Se a mensagem é uma resposta
      # @return [Hash] Resposta da API (mesmo formato do método send)
      #
      # @raise [ArgumentError] Se parâmetros obrigatórios estiverem faltando
      def send_raw(params)
        api_request(params.merge(raw: true))
      end

      private

      ##
      # Executa uma requisição HTTP para a API de mensagens
      #
      # @param params [Hash] Parâmetros da requisição
      # @return [Hash] Resposta parseada da API
      #
      # @raise [ArgumentError] Se credenciais ou chatId estiverem faltando
      # @raise [RuntimeError] Se todas as tentativas falharem
      def api_request(params)
        @config = Settings.load
        validate_parameters(params)
        
        uri = URI.parse(@config['PostRequest']['value'])
        http = configure_http_client(uri)
        request = build_request(uri, params)

        execute_request_with_retries(http, request)
      rescue => e
        handle_error(e)
        { status: 'error', error: e.message }
      end

      ##
      # Valida os parâmetros obrigatórios da requisição
      #
      # @param params [Hash] Parâmetros a serem validados
      # @raise [ArgumentError] Se:
      #   - Credenciais não estiverem configuradas
      #   - chatId não for fornecido
      def validate_parameters(params)
        unless @config.dig('Auth', 'value', 'username') && @config.dig('Auth', 'value', 'password')
          raise ArgumentError, 'Credenciais de autenticação não configuradas'
        end

        raise ArgumentError, 'Parâmetro chatId é obrigatório' unless params[:chatId]
      end

      ##
      # Configura o cliente HTTP com opções de conexão
      #
      # @param uri [URI] Objeto URI com host, porta e esquema (http/https)
      # @return [Net::HTTP] Cliente HTTP configurado com:
      #   - SSL habilitado para conexões HTTPS
      #   - Timeouts configurados
      #   - Verificação SSL desabilitada
      def configure_http_client(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = uri.scheme == 'https'
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
          http.read_timeout = DEFAULT_TIMEOUT
          http.open_timeout = DEFAULT_TIMEOUT / 2
        end
      end

      ##
      # Constrói o objeto de requisição HTTP
      #
      # @param uri [URI] Objeto URI com caminho da requisição
      # @param params [Hash] Parâmetros da mensagem
      # @return [Net::HTTP::Post] Requisição POST configurada com:
      #   - Content-Type: application/json
      #   - Corpo da requisição em JSON
      def build_request(uri, params)
        Net::HTTP::Post.new(uri.request_uri).tap do |request|
          request['Content-Type'] = 'application/json'
          request.body = build_payload(params).to_json
        end
      end

      ##
      # Executa a requisição com mecanismo de retentativas
      #
      # @param http [Net::HTTP] Cliente HTTP configurado
      # @param request [Net::HTTP::Post] Requisição a ser enviada
      # @return [Hash] Resposta parseada da API
      #
      # @raise [RuntimeError] Se todas as tentativas falharem
      def execute_request_with_retries(http, request)
        MAX_RETRIES.times do |attempt|
          begin
            response = http.request(request)
            return parse_response(response)
          rescue Net::ReadTimeout, EOFError, Net::OpenTimeout, SocketError => e
            sleep RETRY_DELAYS[attempt] unless attempt == MAX_RETRIES - 1
          end
        end
        
        raise "Falha após #{MAX_RETRIES} tentativas"
      end

      ##
      # Constrói o payload da requisição no formato esperado pela API
      #
      # @param params [Hash] Parâmetros originais da mensagem
      # @return [Hash] Payload formatado contendo:
      #   - Credenciais de autenticação
      #   - ID do chat
      #   - Mensagem formatada
      #   - Demais parâmetros opcionais
      def build_payload(params)
        {
          username: @config.dig('Auth', 'value', 'username').to_s,
          password: @config.dig('Auth', 'value', 'password').to_s,
          chatId: params[:chatId].to_s,
          message: format_message(params[:message]),
          quoted: params[:quoted],
          code: params[:code],
          raw: params.fetch(:raw, false)
        }.compact
      end

      ##
      # Formata a mensagem para o padrão esperado pela API
      #
      # @param message [Hash,String,nil] Mensagem a ser formatada
      # @return [Hash] Mensagem no formato adequado:
      #   - Hash: usado diretamente
      #   - String: convertida para { text: "..." }
      #   - nil: convertida para { text: "" }
      def format_message(message)
        case message
        when Hash then message
        when nil then { text: '' }
        else { text: message.to_s }
        end
      end

      ##
      # Parseia a resposta HTTP da API
      #
      # @param response [Net::HTTPResponse] Resposta HTTP recebida
      # @return [Hash] Resposta parseada contendo:
      #   - status: 'success' ou 'error'
      #   - data: conteúdo da resposta em caso de sucesso
      #
      # @raise [RuntimeError] Se o status HTTP indicar erro
      def parse_response(response)
        raise "Erro HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
        
        JSON.parse(response.body)
      rescue JSON::ParserError
        { status: 'success', data: response.body }
      end

      ##
      # Trata erros e registra informações detalhadas
      #
      # @param error [Exception] Erro ocorrido
      # @return [Hash] Detalhes do erro formatados contendo:
      #   - timestamp: horário do erro
      #   - error: mensagem de erro
      #   - backtrace: primeiras linhas do stacktrace
      def handle_error(error)
        error_details = {
          timestamp: Time.now.iso8601,
          error: error.message,
          backtrace: error.backtrace&.first(3)
        }
        
        log_error(error_details)
        error_details
      end

      ##
      # Registra erros de forma estruturada
      #
      # @param error_details [Hash] Detalhes do erro contendo:
      #   - timestamp
      #   - error
      #   - backtrace
      # @return [void]
      def log_error(error_details)
        # Em ambiente de produção, considerar integração com:
        # - Sentry
        # - Logstash
        # - Outros sistemas de monitoramento
        STDERR.puts("[ERROR] #{error_details.to_json}")
      end
    end
  end
end