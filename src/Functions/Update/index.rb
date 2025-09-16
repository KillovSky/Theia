# frozen_string_literal: true

require 'net/http'
require 'json'
require 'async'

##
# Módulo Functions::Update - Gerenciador de Atualizações
#
# Responsável por verificar e notificar sobre atualizações disponíveis do software,
# comparando versões locais com remotas de forma assíncrona.
#
# Principais características:
# - Verificação assíncrona de versões
# - Suporte a timeout configurável
# - Mensagens coloridas de status
# - Tratamento robusto de erros (rede, parsing, etc.)
# - Comparação detalhada de versão, build e data
#
# Exemplo de uso:
#   Async { Functions::Update.checkupdates(timeout: 5).wait }
#
module Functions
  module Update
    class << self
      ##
      # URL do package.json remoto no GitHub
      REMOTE_PACKAGE_URL = 'https://raw.githubusercontent.com/KillovSky/Theia/main/package.json'.freeze
      
      ##
      # Caminho local do arquivo package.json
      LOCAL_PACKAGE_PATH = 'package.json'.freeze

      ##
      # Verifica atualizações disponíveis de forma assíncrona
      #
      # @param timeout [Integer] (opcional) Timeout em segundos para a requisição HTTP (padrão: 10)
      # @return [Async::Task] Task assíncrona que retorna:
      #   - true se houver atualização disponível
      #   - false se estiver atualizado ou em caso de erro
      #
      # Exemplo:
      #   task = Functions::Update.checkupdates(timeout: 5)
      #   Async { task.wait } #=> true/false
      def checkupdates(timeout: 10)
        Async do
          begin
            colorfy = Functions::Colors
            local = read_local_package
            remote = fetch_remote_package(timeout)
            if versions_match?(local, remote)
              puts version_message(colorfy, :current)
              false
            else
              puts update_available_message(colorfy, remote)
              true
            end
          
          rescue Net::HTTPError, Timeout::Error => e
            handle_network_error(colorfy, e)
            false
          rescue JSON::ParserError => e
            handle_parse_error(colorfy, e)
            false
          rescue => e
            handle_unknown_error(colorfy, e)
            false
          end
        end
      end

      private

      ##
      # Lê e parseia o package.json local
      #
      # @return [Hash] Conteúdo do package.json parseado contendo:
      #   - version [String] Número da versão
      #   - build_date [String] Data do build
      #   - build_name [String] Nome do build
      #
      # @raise [JSON::ParserError] Se o arquivo JSON for inválido
      # @raise [Errno::ENOENT] Se o arquivo não for encontrado
      def read_local_package
        JSON.parse(File.read(LOCAL_PACKAGE_PATH))
      end

      ##
      # Busca o package.json remoto via HTTP
      #
      # @param timeout [Integer] Timeout em segundos para a requisição
      # @return [Hash] Conteúdo do package.json remoto parseado
      #
      # @raise [Net::HTTPError] Para respostas HTTP 4XX-5XX
      # @raise [Timeout::Error] Se a requisição exceder o timeout
      # @raise [JSON::ParserError] Se o JSON remoto for inválido
      def fetch_remote_package(timeout)
        uri = URI.parse(REMOTE_PACKAGE_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = timeout

        response = http.get(uri.request_uri)
        response.value # Raises HTTPError for 4XX-5XX responses
        JSON.parse(response.body)
      end

      ##
      # Compara versões local e remota
      #
      # @param local [Hash] Dados locais do package.json
      # @param remote [Hash] Dados remotos do package.json
      # @return [Boolean] true se todas as propriedades de versão forem iguais:
      #   - version
      #   - build_date
      #   - build_name
      def versions_match?(local, remote)
        local['version'] == remote['version'] &&
          local['build_date'] == remote['build_date'] &&
          local['build_name'] == remote['build_name']
      end

      ##
      # Gera mensagem de status da versão
      #
      # @param colorfy [Functions::Colors] Instância do módulo de cores
      # @param status [Symbol] :current para versão atualizada
      # @return [String] Mensagem formatada com cores
      def version_message(colorfy, status)
        prefix = colorfy.format('[VERSÃO] ', :cyan)
        
        case status
        when :current
          prefix + colorfy.format('Você está na versão mais recente!', :green)
        end
      end

      ##
      # Gera mensagem de atualização disponível
      #
      # @param colorfy [Functions::Colors] Instância do módulo de cores
      # @param remote [Hash] Dados remotos do package.json contendo:
      #   - version [String]
      #   - build_name [String]
      #   - build_date [String]
      #   - homepage [String]
      # @return [String] Mensagem formatada com cores incluindo:
      #   - Número da versão
      #   - Nome do build
      #   - Data do build
      #   - URL do repositório
      def update_available_message(colorfy, remote)
        title = colorfy.format('ATUALIZAÇÃO DISPONÍVEL ', :red)
        version = colorfy.format(remote['version'], :magenta)
        build = colorfy.format(remote['build_name'].upcase, :blue)
        date = colorfy.format(remote['build_date'].upcase, :yellow)
        url = colorfy.format(remote['homepage'], :green)
        
        "#{title}→ [#{version} ~ #{build} ~ #{date}] | #{url}"
      end

      ##
      # Trata erros de rede/timeout
      #
      # @param colorfy [Functions::Colors] Instância do módulo de cores
      # @param error [Exception] Erro ocorrido (Net::HTTPError ou Timeout::Error)
      # @return [void] Imprime mensagem de erro formatada
      def handle_network_error(colorfy, error)
        puts colorfy.format('→ ERRO: Falha na conexão com o servidor remoto', :red)
        puts "Detalhes: #{error.message}"
      end

      ##
      # Trata erros de parsing JSON
      #
      # @param colorfy [Functions::Colors] Instância do módulo de cores
      # @param error [JSON::ParserError] Erro ocorrido
      # @return [void] Imprime mensagem de erro formatada
      def handle_parse_error(colorfy, error)
        puts colorfy.format('→ ERRO: Dados de versão inválidos', :red)
        puts "Detalhes: #{error.message}"
      end

      ##
      # Trata erros desconhecidos
      #
      # @param colorfy [Functions::Colors] Instância do módulo de cores
      # @param error [Exception] Erro genérico
      # @return [void] Imprime mensagem de erro formatada
      def handle_unknown_error(colorfy, error)
        puts colorfy.format('→ ERRO: Falha desconhecida ao verificar atualizações', :red)
        puts "Detalhes: #{error.class}: #{error.message}"
      end
    end
  end
end