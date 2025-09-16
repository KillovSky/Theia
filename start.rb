#!/usr/bin/env ruby
# frozen_string_literal: true

##
# Ponto de entrada principal da Theia
#
# Responsável por:
# - Carregar dependências essenciais
# - Inicializar o código principal
# - Capturar e tratar erros globais
# - Garantir saída com código de erro apropriado
#
# Fluxo de execução:
# 1. Carrega configurações do sistema
# 2. Carrega inicializadores
# 3. Carrega módulo de mensagens
# 4. Inicia o sistema de comandos e funções
#
# @example Execução básica
#   ruby ./start.rb
#
# @exitcode 0 Em caso de sucesso
# @exitcode 1 Em caso de erro na inicialização
begin
  # Carrega dependências na ordem correta
  require_relative 'src/Config/index'
  require_relative 'src/Initialize/index'
  require_relative 'src/Functions/Message/index'
  
  # Inicia aplicação principal
  Theia::Application.new.run
rescue LoadError => e
  # Para erro ao carregar arquivos/dependências
  puts "Erro ao carregar dependências: #{e.message}"
  exit 1
rescue => e
  # Para erro genérico não tratado
  puts "Erro fatal: #{e.class} - #{e.message}"
  exit 1
end