<a id="top"></a>

<h1 align="center">MarketWatch</h1>

<p align="center">
  <strong>Cotações de criptomoedas em um app iOS nativo, reativo e testável.</strong><br />
  Aplicativo UIKit que lista criptoativos, exibe preço e variação e detalha cada ativo a partir da API pública da CoinGecko.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-em%20desenvolvimento-1F6FEB" alt="Status: em desenvolvimento" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/licen%C3%A7a-MIT-1F6FEB" alt="Licença: MIT" /></a>
</p>

<p align="center">
  <a href="#status"><strong>STATUS →</strong></a>
  &nbsp;·&nbsp;
  <a href="#stack">STACK</a>
  &nbsp;·&nbsp;
  <a href="#decisoes">DECISÕES</a>
  &nbsp;·&nbsp;
  <a href="#licenca">LICENÇA</a>
</p>

---

## Visão geral

O MarketWatch é a resposta a um desafio técnico para desenvolvimento iOS: um MVP de acompanhamento de mercado em que o usuário vê uma lista de criptoativos com cotação atual, toca em um ativo para ver detalhes e busca por nome ou símbolo.

O projeto prioriza clareza de arquitetura, programação reativa idiomática e testes de comportamento. Não contempla autenticação, carteira, compra e venda de ativos ou qualquer operação financeira.

> **Em desenvolvimento.** Este repositório ainda não contém o projeto Xcode. As seções abaixo descrevem o plano aprovado; nada nelas está implementado até que a tabela de status diga o contrário.

<a id="status"></a>

## Status

Status em 2026-10-17.

| Entrega | Status |
|---|---|
| Estrutura inicial do repositório | Concluída |
| Projeto Xcode e dependências CocoaPods | Planejada |
| Arquitetura MVVM-C | Planejada |
| Integração com a CoinGecko | Planejada |
| Listagem reativa de criptomoedas | Planejada |
| Tela de detalhes com gráfico histórico | Planejada |
| Busca, pull-to-refresh e estados de interface | Planejada |
| Testes unitários com Swift Testing | Planejada |
| Integração do design aprovado | Planejada |

<a id="stack"></a>

## Stack

**Planejada:** versões serão confirmadas pelo `Podfile.lock` quando o projeto Xcode for criado.

| Camada | Escolha |
|---|---|
| Interface | UIKit, Auto Layout programático |
| Arquitetura | MVVM-C |
| Reatividade | RxSwift e RxCocoa |
| Rede | Alamofire |
| Imagens | Kingfisher |
| Dependências | CocoaPods |
| Testes | Swift Testing |
| Qualidade | SwiftLint e SwiftFormat |
| Plataforma | iOS 16.0 ou superior, Swift 5 language mode |

<a id="decisoes"></a>

## Decisões técnicas

| Decisão | Registro |
|---|---|
| Gerenciamento de dependências: CocoaPods em vez de Swift Package Manager | [ADR-001](docs/adr/ADR-001-dependency-management.md) |

## Fonte de dados

Os dados de mercado virão da [API da CoinGecko](https://docs.coingecko.com/), usada sem chave por padrão. Criptoativos são negociados 24 horas por dia; por isso, o app não exibirá "fechamento oficial", e sim um preço de referência de 24 horas, documentado quando implementado.

<a id="licenca"></a>

## Licença

MIT. Consulte [LICENSE](LICENSE).

<p align="right"><a href="#top">Voltar ao topo ↑</a></p>
