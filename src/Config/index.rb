# frozen_string_literal: true

require 'json'
require 'pathname'

##
# Módulo Settings - Gerenciador centralizado de configurações
#
# Responsável por:
# - Carregar e validar configurações do sistema
# - Gerenciar cache de configurações
# - Fornecer acesso thread-safe às configurações
# - Validar estrutura básica das configurações
#
# @example Carregar configurações
#   config = Settings.load
#
# @example Recarregar configurações (ignorando cache)
#   Settings.reload!
#
# @example Acessar configuração específica
#   Settings.load['WebSocket']['value']
module Settings
  class << self
    ##
    # Caminho absoluto para o arquivo de configuração principal
    CONFIG_PATH = File.expand_path('../Settings/config.json', __dir__).freeze

    ##
    # Carrega as configurações do arquivo config.json
    #
    # @return [Hash] Configurações carregadas contendo:
    #   - Auth: credenciais de autenticação
    #   - WebSocket: configurações de conexão
    #   - PostRequest: configurações de API
    #   - Outras configurações customizadas
    #
    # @raise [JSON::ParserError] Se o arquivo JSON for inválido
    # @raise [RuntimeError] Se chaves obrigatórias estiverem faltando
    #
    # @note Utiliza cache após primeira carga (@config)
    def load
      @config ||= load_config(CONFIG_PATH)
    end

    ##
    # Recarrega as configurações do arquivo (ignorando cache)
    #
    # @return [Hash] Configurações recarregadas
    # @see #load
    def reload!
      @config = load_config(CONFIG_PATH)
      @symlinks = nil # Limpa cache de symlinks
      @config
    end

    private

    ##
    # Carrega e valida o arquivo de configuração
    #
    # @param path [String] Caminho absoluto do arquivo JSON
    # @return [Hash] Configurações parseadas
    # @raise [JSON::ParserError] Se o JSON for inválido
    # @raise [RuntimeError] Se o arquivo não existir ou chaves obrigatórias faltando
    def load_config(path)
      unless File.exist?(path)
        raise "Arquivo de configuração não encontrado: #{path}"
      end

      JSON.parse(File.read(path)).tap do |config|
        validate_config!(config) if path == CONFIG_PATH
      end
    rescue JSON::ParserError => e
      raise "JSON inválido em #{path}: #{e.message}"
    end

    ##
    # Valida estrutura básica das configurações
    #
    # @param config [Hash] Configurações carregadas
    # @raise [RuntimeError] Se alguma chave obrigatória estiver faltando
    #
    # @note Chaves obrigatórias:
    #   - Auth: Para autenticação
    #   - WebSocket: Para conexão WebSocket
    #   - PostRequest: Para requisições HTTP
    def validate_config!(config)
      %w[Auth WebSocket PostRequest].each do |key|
        unless config.key?(key)
          raise "Chave de configuração obrigatória faltando: #{key}"
        end
      end
    end
  end
end

# Carrega as configurações imediatamente ao inicializar o módulo
Settings.load