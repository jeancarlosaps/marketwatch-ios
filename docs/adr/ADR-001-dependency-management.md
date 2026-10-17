# ADR-001 — Estratégia de gerenciamento de dependências

- **Status:** Aceito
- **Data:** 2026-10-17

## Contexto

O MarketWatch é um aplicativo iOS em UIKit desenvolvido como resposta a um desafio técnico. O enunciado define requisitos técnicos obrigatórios:

- dependências gerenciadas com **CocoaPods**, incluindo Alamofire, RxSwift e RxCocoa;
- o projeto deve executar apenas com `pod install` seguido de Cmd+R.

Fatos verificados em 2026-10-17:

| Fato | Fonte |
|---|---|
| O trunk do CocoaPods deixa de aceitar novas versões em 2026-12-02; builds existentes continuam funcionando | [CocoaPods Specs Repo](https://blog.cocoapods.org/CocoaPods-Specs-Repo/) |
| O RxSwift 6.10.0 descontinuou oficialmente o suporte a CocoaPods; a última versão publicada no trunk é a 6.9.0 | [RxSwift 6.10.0](https://github.com/ReactiveX/RxSwift/releases/tag/6.10.0), índice do CDN do CocoaPods |
| Alamofire 5.12.2 e Kingfisher 8.14.0 continuam publicados no trunk | Índice do CDN do CocoaPods |
| CocoaPods 1.16.2 e Xcode 26.5 no ambiente de desenvolvimento | `pod env`, `xcodebuild -version` |

## Alternativas consideradas

| Alternativa | Prós | Contras |
|---|---|---|
| **CocoaPods** | Atende ao requisito do desafio; ecossistema maduro; `Podfile.lock` fixa versões | Ferramenta externa (Ruby); modifica o projeto e cria workspace; trunk em modo somente leitura a partir de dezembro de 2026; RxSwift congelado na 6.9.0 |
| **Swift Package Manager** | Integrado ao Xcode; sem ferramentas externas; manifesto declarativo; caminho atual do ecossistema Swift; RxSwift recebe atualizações apenas por SPM | Não atende ao requisito explícito do desafio |
| **CocoaPods + SPM** | — | Duas fontes de verdade para as mesmas bibliotecas; risco de símbolos duplicados; complexidade sem ganho |

## Decisão

Utilizar **somente CocoaPods** para as dependências do aplicativo.

- Versões fixadas no `Podfile` e travadas no `Podfile.lock`, que é versionado.
- O diretório `Pods/` não é versionado; `pod install` reconstrói o ambiente a partir do lock.
- RxSwift e RxCocoa fixados em `6.9.0`, última versão disponível no CocoaPods.
- Um hook `post_install` alinha o deployment target dos pods ao do aplicativo (iOS 16.0), evitando avisos de alvos abaixo do mínimo suportado pelo Xcode 26.
- Nenhuma biblioteca é integrada simultaneamente por SPM.

Em um projeto novo sem essa restrição externa, SPM seria a escolha inicial.

## Consequências

- O RxSwift não receberá correções posteriores à 6.9.0 neste projeto. A compatibilidade com Xcode 26.5 e Swift 6.3 é validada no build e registrada no README.
- Após 2026-12-02, nenhuma dependência receberá novas versões pelo trunk; o `Podfile.lock` garante builds reprodutíveis.
- Uma migração futura para SPM é direta: as camadas que usam as bibliotecas não dependem do gerenciador. Ela exigiria nova decisão, porque altera o requisito do desafio.
