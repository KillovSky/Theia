<p align="center">
    <h1 align="center">Projeto Theia</h1>
    <a href="https://github.com/KillovSky/Theia/blob/main/LICENSE"><img alt="GitHub License" src="https://img.shields.io/github/license/KillovSky/Theia?color=blue&label=License&style=flat-square"></a>
    <a href="https://github.com/KillovSky/Theia"><img alt="GitHub repo size" src="https://img.shields.io/github/repo-size/KillovSky/Theia?label=Size%20%28With%20.git%20folder%29&style=flat-square"></a>
    <a href="https://api.github.com/repos/KillovSky/Theia/languages"><img alt="GitHub Languages" src="https://img.shields.io/github/languages/count/KillovSky/Theia?label=Code%20Languages&style=flat-square"></a>
    <a href="https://github.com/KillovSky/Theia/blob/main/.github/CHANGELOG.md"><img alt="GitHub Version" src="https://img.shields.io/github/package-json/v/KillovSky/Theia?label=Latest%20Version&style=flat-square"></a>
    <a href="https://github.com/KillovSky/Theia/blob/main/.github/CHANGELOG.md"><img alt="Project Codename" src="https://img.shields.io/github/package-json/build_name/KillovSky/Theia?label=Latest%20Codename"></a>
    <a href="https://github.com/KillovSky/Theia/blob/main/.github/CHANGELOG.md"><img alt="Last Update" src="https://img.shields.io/github/package-json/build_date/KillovSky/Theia?label=Latest%20Update"></a>
    <a href="https://github.com/KillovSky/Theia/commits/main"><img alt="GitHub Commits" src="https://img.shields.io/github/commit-activity/y/KillovSky/Theia?label=Commits&style=flat-square"></a>
    <a href="https://github.com/KillovSky/Theia/stargazers/"><img title="GitHub Stars" src="https://img.shields.io/github/stars/KillovSky/Theia?label=Stars&style=flat-square"></a>
    <a href="https://github.com/KillovSky/Theia/network/members"><img title="GitHub Forks" src="https://img.shields.io/github/forks/KillovSky/Theia?label=Forks&style=flat-square"></a>
    <a href="https://github.com/KillovSky/Theia/watchers"><img title="GitHub Watchers" src="https://img.shields.io/github/watchers/KillovSky/Theia?label=Watchers&style=flat-square"></a>
    <a href="http://isitmaintained.com/project/KillovSky/Theia"><img alt="Issue Resolution" src="http://isitmaintained.com/badge/resolution/KillovSky/Theia.svg"></a>
    <a href="http://isitmaintained.com/project/KillovSky/Theia"><img alt="Open Issues" src="http://isitmaintained.com/badge/open/KillovSky/Theia.svg"></a>
    <a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FKillovSky%2FTheia&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=Views&edge_flat=false"/></a>
    <a href="https://github.com/KillovSky/Theia/pulls"><img alt="Pull Requests" src="https://img.shields.io/github/issues-pr/KillovSky/Theia?label=Pull%20Requests&style=flat-square"></a>
    <a href="https://github.com/KillovSky/Theia/graphs/contributors"><img alt="Contributors" src="https://img.shields.io/github/contributors/KillovSky/Theia?label=Contribuidores&style=flat-square"></a>
</p>

# O que é?

O Projeto Theia é um plugin opcional desenvolvido em Ruby para o [Projeto Íris](https://github.com/KillovSky/Iris). Este plugin permite a adição de funcionalidades personalizadas em Ruby, incluindo o uso de ilimitadas GEMs e outros códigos em Ruby Scripting. Com o Projeto Theia, você pode personalizar o Projeto Íris sem a necessidade de modificar seu código principal ou aprender Node.js (JavaScript).

## Requisitos

Para garantir o correto funcionamento do Projeto Theia, o Projeto Íris deve estar ativo. Observe que a versão atual do Projeto Theia é experimental e foi desenvolvida em pouco tempo para fins de aprendizado, podendo conter erros menores.

1. **Ruby**:
    - É recomendada a versão mais recente disponível, mas acima ou equivalente da v3.3.5 provavelmente funcionará.
2. **Projeto Íris**:
    - Deve estar instalada e em execução.
3. **Dependências do Projeto Íris**:
    - Instale todas as dependências necessárias do Projeto Íris para assegurar o correto funcionamento da Theia.

## Instalação

Para instalar as dependências do Projeto Theia, você tem duas opções:

1. **Usando NPM**:
   - Embora o Projeto Theia **NÃO UTILIZE** JavaScript, você pode instalar os módulos Ruby via NPM por conta das configurações inseridas para facilitar o uso de quem veio pelo Node.js.
   - Utilize o seguinte comando:
     ```bash
     npm run install
     ```
   - Este comando executará o `GEM` por meio do NPM para instalar os requisitos do Ruby.
   - O NPM também pode ser usado para iniciar, como dito na etapa **Execução**.

2. **Alternativamente**:
   - Instale diretamente com `BUNDLE`:
     ```bash
     bundle install
     ```
   - Caso você não possua o comando `bundle`, tente instalar usando:
     ```bash
     gem install bundler
     ```
   - Alternativamente, para Linux, você pode tentar usar:
     ```bash
     sudo gem install bundler
     ```
   - Caso você não consiga, entre em contato com o suporte do projeto ou tente encontrar guias que funcionem para seu sistema operacional.

## Execução

Não é necessário qualquer scan de QR, inserção de código ou demais, basta que sua Íris esteja rodando.

Após a instalação das dependências, você pode executar o Projeto Theia de duas maneiras:

1. **Usando NPM**:
   - O Projeto Theia pode ser iniciado via NPM com um dos seguintes comandos:
     ```bash
     npm start
     ```
     ou
     ```bash
     npm run start
     ```
   - Isso executará o script Ruby diretamente por meio do NPM.

2. **Alternativamente**:
   - Execute diretamente com Ruby:
     ```bash
     ruby start.rb
     ```

## Modificação

Se você não tem experiência com Ruby, a maneira mais simples de modificar o Projeto Theia é através do sistema `Cases`, localizado em `src/Commands/Cases/index.rb`. Lá você encontrará um comando de exemplo que pode ser usado como base para criar novos comandos.

Todos os parâmetros do Projeto Íris estão acessíveis via `env['nomeDaVariavel']`, permitindo que você utilize as funcionalidades do Projeto Íris em seu código Ruby, independente de como seja feito, incluindo `async`.

## Configuração

Para testar o Projeto Theia com versões anteriores do Projeto Íris, ajuste a porta HTTPS do Projeto Íris [localizada aqui](https://github.com/KillovSky/Iris/blob/main/lib/Functions/Works/Terminal/utils.json#L211) para 3000, ou edite a porta na configuração `config.json`, localizada na pasta `settings` do Projeto Theia.

## Detalhes Adicionais

**Informações da Versão**:
- **Codinome**: Ether
- **Versão**: v1.0.0
- **Tipo**: BETA
- **Erros**: Nenhum bug grave detectado
- **Data de Lançamento**: 15/09/2025
- **Observações**: Esta versão pode apresentar problemas menores não graves devido à ausência de alguns parâmetros opcionais ainda não integrados no Projeto Íris. Atualizações futuras do Projeto Íris resolverão essas questões, garantindo a integração completa e o funcionamento adequado dos parâmetros. Não será necessário reinstalar a Theia para aplicar essas atualizações, pois os parâmetros já estarão incorporados nas futuras versões da Íris, e nenhuma intervenção adicional será necessária no Projeto Theia, a menos que haja novas atualizações da mesma.

## Desenvolvimento Futuro

Estarei trabalhando em novas funcionalidades e atualizações tanto para o Projeto Íris quanto para o Projeto Theia, e eventualmente em versões para outras linguagens de programação. Fique atento às atualizações e acompanhe as redes sociais para mais informações!

Obrigado pelo seu interesse e apoio! Vamos continuar evoluindo juntos a um open-source melhor! ❤️