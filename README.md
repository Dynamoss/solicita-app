# 🩺 Solicita — App de Acompanhamento de Solicitações

Aplicativo mobile em **Flutter** para rastreamento e gestão de chamados/solicitações de serviço, construído com **Clean Architecture**, **offline-first** e gerenciamento de estado com **BLoC/Cubit**.

> Teste técnico — Desenvolvedor(a) Mobile Sênior.
> O "coração do desafio" — **modo offline com fila de sincronização** — é o ponto onde concentrei o maior cuidado de design e de testes.

---

## 📑 Índice

1. [Funcionalidades](#-funcionalidades)
2. [Como executar](#-como-executar)
3. [Arquitetura e decisões de design](#-arquitetura-e-decisões-de-design)
4. [Estratégia offline / sincronização (o coração)](#-estratégia-offline--sincronização-o-coração)
5. [Stack e justificativas](#-stack-e-justificativas)
6. [Estrutura de pastas](#-estrutura-de-pastas)
7. [Testes](#-testes)
8. [Whitelabel](#-whitelabel)
9. [Diferencial de IA](#-diferencial-de-ia)
10. [Uso de IA generativa no desenvolvimento](#-uso-de-ia-generativa-no-desenvolvimento)
11. [O que eu faria diferente com mais tempo](#-o-que-eu-faria-diferente-com-mais-tempo)

---

## ✨ Funcionalidades

| Requisito | Status | Onde |
|---|---|---|
| **Login** funcional (mockado) | ✅ | `features/auth` |
| **Armazenamento seguro do token** | ✅ | `flutter_secure_storage` (KeyStore/Keychain) — `auth_local_datasource.dart` ([detalhes](#-segurança-do-token-em-repouso-e-em-trânsito)) |
| **Proteção de rotas privadas** | ✅ | guarda no `go_router` (`app/router.dart`) |
| **Listagem com filtro reativo por status** | ✅ | `StatusFilterBar` + `RequestsListCubit` |
| **Paginação** (scroll infinito) | ✅ | `RequestsListCubit.loadMore` |
| **Pull-to-refresh** | ✅ | `RefreshIndicator` na lista |
| **Tela de detalhe rica** | ✅ | `request_detail_page.dart` |
| **Alteração rápida de status** | ✅ | seletor de status no detalhe |
| **Criação com formulário validado** | ✅ | `create_request_page.dart` |
| **Cache local** | ✅ | SQLite (`sqflite`) |
| **Fila local de sincronização** | ✅ | tabela `sync_queue` + `RequestRepositoryImpl` |
| **Sincronização automática ao reconectar** | ✅ | `SyncCubit` + `connectivity_plus` |
| **Tratamento de estados (loading / erro / vazio)** | ✅ | `state_views.dart` |
| **Diferencial — IA** (categoria/resumo) | ✅ | `features/ai` |
| **Diferencial — Whitelabel** | ✅ | `BrandCubit` + `AppTheme` |
| **Testes unitários (lógica + offline/sync)** | ✅ | `test/` (38 testes) |

---

## 🚀 Como executar

Pré-requisitos: **Flutter 3.41+** (Dart 3.11+) e **Node.js** (para o mock).

### 1) Subir o mock da API (json-server)

```bash
cd mock_server
npm install        # instala json-server (versão fixada: 0.17.4)
npm start          # sobe em http://localhost:3000 (com 300ms de latência simulada)
```

Endpoints disponíveis: `GET/POST/PATCH /requests` com paginação (`_page`, `_limit`),
ordenação (`_sort`, `_order`) e filtro (`?status=open`).

### 2) Rodar o app

O endereço da API é injetado via `--dart-define` (sem segredos no código).

**Android (emulador)** — o emulador não enxerga `localhost`, use `10.0.2.2`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

**Android (dispositivo físico)** — use o IP da sua máquina na rede:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
```

**Windows desktop** (forma rápida de testar sem emulador):
```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3000
```
> ⚠️ No Windows, o build desktop exige **Developer Mode** habilitado (suporte a symlink dos plugins):
> `start ms-settings:developers`. Isso **não** afeta os testes nem o build Android.

**Login:** qualquer e-mail válido + senha com 6+ caracteres.
Os campos já vêm preenchidos com `demo@cuidar.com` / `123456`.

### 3) (Opcional) Ativar a IA real

Sem chave, a sugestão de categoria/resumo funciona via heurística on-device.
Para usar um LLM real, passe a chave. O provider é **plugável** (`AI_PROVIDER`,
default `anthropic`):

```bash
# Anthropic (default)
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=AI_API_KEY=sk-ant-...

# OpenAI (ou um gateway compatível)
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=AI_PROVIDER=openai \
  --dart-define=AI_API_KEY=sk-...
```

| `--dart-define` | Default | Para quê |
|---|---|---|
| `AI_PROVIDER` | `anthropic` | `anthropic` ou `openai` (cobre gateways compatíveis) |
| `AI_API_KEY` | *(vazio)* | Chave; vazia → heurística on-device |
| `AI_BASE_URL` | *(default do provider)* | Endpoint próprio/proxy |
| `AI_MODEL` | *(default do provider)* | Modelo a usar |

### 4) Testar o modo offline (roteiro sugerido)

1. Suba o mock e o app; abra a lista (dados carregam e ficam em cache).
2. **Pare o `json-server`** (ou ative o modo avião / desligue o Wi-Fi).
3. Crie uma nova solicitação e/ou altere um status → aparecem **na hora** com o selo **"Pendente"**; o banner mostra a fila.
4. **Reabra a conexão** (suba o mock de novo) → o `SyncCubit` sincroniza **automaticamente** e o selo "Pendente" some.

---

## 🏛 Arquitetura e decisões de design

### Clean Architecture (3 camadas por feature)

```
presentation  →  domain  ←  data
   (Cubit)       (puro)     (impl)
```

- **domain** — núcleo puro, sem Flutter: *entities*, contratos de *repositories* e *use cases*. Não conhece HTTP, SQLite ou widgets.
- **data** — implementações: *data sources* (remoto/local), *models* (serialização) e os *repositories* que orquestram tudo.
- **presentation** — *Cubits* + páginas/widgets. Só conversa com *use cases*.

**Regra de dependência:** as setas apontam para dentro. `data` e `presentation` dependem de `domain`; `domain` não depende de ninguém. Isso mantém a regra de negócio testável e independente de framework.

### Por que esta divisão?

- **Testabilidade:** cada *use case* e o repositório são testados isoladamente, com os limites mockados. Trocar `sqflite` por Isar, ou `json-server` por uma API real, não toca em `domain` nem em `presentation`.
- **Cada erro é explícito:** todas as operações que podem falhar retornam `Either<Failure, T>` (`fpdart`). O chamador é **obrigado** a tratar o caminho de erro — nada de exceção atravessando camadas silenciosamente. Exceções de transporte (`ServerException`, `CacheException`) são capturadas no repositório e mapeadas para `Failure`s semânticas (`NetworkFailure`, `ServerFailure`, `CacheFailure`, `AuthFailure`).

### Gerenciamento de estado: **BLoC/Cubit** (justificativa)

Escolhi `flutter_bloc` por ser a opção mais madura e previsível para um app com **estado assíncrono e reativo** (sync em background, conectividade, paginação):

- Estados **imutáveis** e comparáveis (`Equatable`) → rebuilds previsíveis e fáceis de depurar.
- Separação clara entre **intenção** (métodos do Cubit) e **estado** (classe de estado), o que torna os fluxos triviais de testar com `bloc_test`.
- **Cubit vs Bloc:** usei **Cubit** em todos os casos. As telas têm comandos imperativos simples (`load`, `loadMore`, `changeStatus`) sem necessidade de um *stream* de eventos com transformações (debounce/concat). Cubit entrega a mesma robustez com menos cerimônia — preferir a ferramenta mais simples que resolve o problema. Se, por exemplo, a busca textual com debounce entrasse no escopo, um `Bloc` com `EventTransformer` seria justificável ali.

### Injeção de dependências

`get_it` como service locator, **sem code generation** (decisão consciente): o grafo fica explícito e legível em um único arquivo (`core/di/injection.dart`), sem mágica de build_runner. Os *Cubits* de página são `factory` (instância nova por tela); repositórios/serviços são `lazySingleton`.

### 🔒 Segurança do token (em repouso e em trânsito)

O requisito pedia **armazenamento seguro do token**. Tratei o token de sessão como um segredo de ponta a ponta, não só na gravação:

**Em repouso — `flutter_secure_storage` (`auth_local_datasource.dart`):**

- **Android:** os defaults da v10 já são fortes — dados cifrados com **AES-GCM** e a chave protegida por **RSA-OAEP-SHA256** no **Android KeyStore** (chave não exportável, presa ao hardware). O token **nunca** toca `SharedPreferences`, o SQLite ou logs de produção.
- **Apple (iOS/macOS):** item do **Keychain** com acessibilidade `first_unlock_this_device` — o token fica **preso ao aparelho** e não é carregado para outro device em backup/restore.
- **Backup do Android desativado** (`allowBackup="false"`, `fullBackupContent="false"`) para o blob cifrado nunca sair do dispositivo via auto-backup.

**Em trânsito — *network security config* + ATS:**

- O token vai como `Authorization: Bearer` (interceptor do `dio`). Tráfego **HTTP em texto plano é bloqueado em release**, exceto os hosts locais de desenvolvimento (`localhost`, `127.0.0.1`, `10.0.2.2`). Qualquer domínio público exige **HTTPS**.
- No **iOS**, o App Transport Security é mantido, com a exceção escopada `NSAllowsLocalNetworking` (apenas redes locais).
- A liberação ampla de cleartext existe **somente no build de debug** (`src/debug/res/xml/network_security_config.xml`), para que o avaliador rode o mock no endereço que quiser (`localhost`, `10.0.2.2` no emulador, ou o IP da LAN num device físico) sem nenhuma alteração. **Nada está vinculado a um IP fixo** — o host vem de `--dart-define=API_BASE_URL`.

---

## 💙 Estratégia offline / sincronização (o coração)

O princípio central é **cache local como fonte única de verdade (single source of truth)**: a UI sempre lê do SQLite. O remoto é tratado como um **alvo de sincronização**, não como a fonte que a tela consome. Resultado: a tela renderiza **idêntica** online e offline.

### Leitura (offline-first)

```
getRequests(page, status):
  online?  → busca a página no remoto → atualiza o cache → lê a página do cache
  offline? → lê a página direto do cache
  remoto falhou no meio? → degrada graciosamente para o cache
```

### Escrita (otimista + fila)

Toda mutação (`createRequest`, `updateStatus`) é **otimista**:

1. Grava imediatamente no cache (a UI reflete na hora, com selo "Pendente").
2. Enfileira uma `SyncAction` na tabela `sync_queue`.
3. Se **online**, tenta empurrar na hora; se falhar (ou offline), a ação **permanece na fila**.

### Sincronização

- A fila é drenada em **ordem FIFO** (`created_at ASC`) — as mutações são reproduzidas na ordem em que aconteceram (ex.: `create` antes do `updateStatus` da mesma entidade).
- Um erro de **conectividade** durante a drenagem **aborta** a rodada (não adianta continuar offline); outros erros incrementam `retry_count` e seguem.
- O **`SyncCubit`** ouve `connectivity_plus`: quando a conexão **retorna** e há itens na fila, dispara a sincronização **automaticamente**. Também expõe a contagem pendente para o banner no topo da lista.

```
┌── UI (otimista) ──┐      ┌─ sync_queue (SQLite) ─┐     ┌─ Remoto ─┐
│ cria/edita        │ ───▶ │ create / update_status │ ──▶ │ json-srv │
│ vê "Pendente"     │      │ FIFO, retry_count      │     └──────────┘
└───────────────────┘      └────────────┬───────────┘
        ▲                                │ ao reconectar (SyncCubit)
        └──── pendingSync = false ◀──────┘
```

Esse fluxo é coberto por testes de integração reais (SQLite em memória) — veja abaixo.

---

## 🧰 Stack e justificativas

| Pacote | Papel | Por quê |
|---|---|---|
| `flutter_bloc` | Estado | Maduro, testável, estados imutáveis |
| `get_it` | DI | Explícito, sem codegen |
| `dio` | HTTP | Interceptors (token), timeouts, tratamento de erro |
| `sqflite` (+`_common_ffi`) | Cache + fila | SQL relacional é ideal para a fila (ordem, retry); `ffi` roda em desktop/testes em memória |
| `flutter_secure_storage` | Token | Keychain (Apple) / Android KeyStore — AES-GCM ([detalhes](#-segurança-do-token-em-repouso-e-em-trânsito)) |
| `connectivity_plus` | Rede | Detecta retorno da conexão p/ auto-sync |
| `go_router` | Navegação | Rotas declarativas + **guarda de rota** via `refreshListenable` |
| `fpdart` | `Either` | Erros como valores, no tipo |
| `equatable` | Igualdade | Estados/entidades comparáveis |
| `shared_preferences` | Preferências | Persistir a marca (whitelabel) |
| `uuid` | IDs locais | IDs estáveis para itens criados offline |
| `mocktail` / `bloc_test` | Testes | Mocks sem codegen + helpers de bloc |

---

## 📂 Estrutura de pastas

```
lib/
├── app/                      # composição: App, router (guarda), bootstrap
├── core/
│   ├── config/               # AppConfig (dart-define) + Brand (whitelabel)
│   ├── database/             # AppDatabase (schema sqflite)
│   ├── di/                   # injection.dart (get_it)
│   ├── error/                # Failures (domínio) e Exceptions (data)
│   ├── network/              # Dio factory + NetworkInfo
│   ├── theme/                # AppTheme + BrandCubit
│   ├── usecase/              # contratos base de UseCase
│   ├── presentation/widgets/ # views de estado (loading/erro/vazio), brand picker
│   └── utils/                # typedefs (Either), Paginated, datas
└── features/
    ├── auth/                 # login mockado + token seguro + sessão
    │   └── data / domain / presentation
    ├── requests/             # núcleo: listagem, detalhe, criação, OFFLINE/SYNC
    │   ├── data/datasources  #   remoto (dio) + local (sqflite: cache + fila)
    │   ├── data/repositories #   RequestRepositoryImpl (offline-first)
    │   ├── domain            #   entidades, contratos, use cases
    │   └── presentation      #   cubits (lista, detalhe, criação, sync) + UI
    └── ai/                   # diferencial IA (porta + impl real/fallback)
        └── data/llm/         #   LlmClient + AnthropicClient / OpenAiClient
```

---

## 🧪 Testes

```bash
flutter test
```

**38 testes**, focados na lógica de negócio e nos **fluxos críticos de offline/sync**:

- `request_repository_impl_test.dart` — **offline-first + fila** ponta a ponta, usando **SQLite real em memória** (só o remoto e a conectividade são mockados): criação offline enfileira; online sincroniza e limpa a fila; falha mantém na fila; `syncPending` drena FIFO; leitura degrada para cache.
- `request_local_datasource_test.dart` — paginação por `created_at` (limit/offset) e **ordem FIFO** da fila.
- `sync_cubit_test.dart` — **auto-sync ao reconectar** com fila pendente (e o caso de não sincronizar sem pendências).
- `requests_list_cubit_test.dart` — load, erro, `loadMore` (append sem duplicar id), guarda de "não há mais páginas".
- `auth_repository_impl_test.dart` — login persiste o token; credenciais inválidas viram `AuthFailure`; logout limpa o storage.
- `local_ai_service_test.dart` — categorização heurística e limites do resumo.
- `remote_ai_service_test.dart` — orquestração provider-agnóstica: parse do JSON do LLM, normalização de categoria e **fallback** para a heurística em falha/sem-JSON (com `LlmClient` stub).
- `llm_clients_test.dart` — cada provider (`AnthropicClient`/`OpenAiClient`) envia o protocolo correto (headers/body) e lê o formato de resposta certo, com `Dio` mockado.

> Testar o repositório contra um SQLite real (em vez de mockar o data source) foi uma decisão deliberada: dá altíssima fidelidade ao comportamento de fila/cache, que é exatamente o "coração" avaliado.

---

## 🎨 Whitelabel

Cada marca é **apenas dados** (`core/config/brand.dart`): id, nome, *tagline* e uma cor semente. O `AppTheme` deriva todo o `ColorScheme` (claro/escuro) a partir dessa cor via `ColorScheme.fromSeed`. Trocar de marca (ícone 🎨 na tela de login ou na lista) emite um novo `Brand` no `BrandCubit`, o `MaterialApp` reconstrói o tema **na hora** e a escolha é persistida. Adicionar um novo cliente = **uma entrada** em `Brands.all`. Há 3 marcas de exemplo (CuidarApp, AtendePro, HelpDesk+).

A marca inicial também pode vir por build: `--dart-define=BRAND=corporate`.

---

## 🤖 Diferencial de IA

Na criação de uma solicitação, o botão **"Sugerir categoria/resumo com IA"** analisa a descrição e preenche a categoria + um resumo.

Arquitetura plugável (`features/ai`): a porta de domínio `AiService` tem duas implementações:
- **`RemoteAiService`** — chama um LLM quando `AI_API_KEY` está configurada;
- **`LocalAiService`** — heurística determinística on-device (palavras-chave + resumo extrativo).

O `RemoteAiService` **encapsula** o fallback: se não há chave, a rede falha ou a resposta não faz parse, ele degrada **transparentemente** para a heurística (a UI sinaliza "modo offline"). Assim o diferencial é robusto na avaliação mesmo **sem** chave.

#### Abstração multi-provider (`LlmClient`)

O `RemoteAiService` é **agnóstico de provider**: ele cuida só da *orquestração* (montar o prompt, extrair o JSON, validar a categoria, fazer fallback) e delega o *transporte* a um `LlmClient`:

```
RemoteAiService ──▶ LlmClient (port)
                       ├── AnthropicClient   (x-api-key, content[0].text)
                       └── OpenAiClient       (Bearer, choices[0].message.content)
```

Cada `LlmClient` encapsula o "formato do fio" do seu provider — headers, corpo da requisição e parsing da resposta. **Adicionar um provider** (Gemini, Ollama, um gateway interno) é uma nova implementação de `LlmClient` + um `case` em `_buildLlmClient` (`core/di/injection.dart`); nada acima muda. A seleção é feita por `AI_PROVIDER` na composição (DI), mantendo o mesmo princípio de inversão de dependência do resto do app.

> Os dois clients têm testes que verificam o protocolo correto (headers/body/parsing) com `Dio` mockado, e o `RemoteAiService` é testado com um `LlmClient` *stub* — provando a orquestração e o fallback sem rede real.

---

## 📝 Uso de IA generativa no desenvolvimento

Conforme solicitado no enunciado, declaro o uso de IA:

- **Ferramenta:** Claude (modelo Opus da Anthropic), via **Claude Code** (assistente de codificação em terminal).
- **Como foi usada:**
  - Estruturação inicial do projeto em Clean Architecture e *scaffolding* das camadas/arquivos.
  - Implementação dos *boilerplates* repetitivos (models, data sources, cubits) sob minha orientação de arquitetura.
  - Apoio na escrita dos testes e deste README.
- **Revisão:** todo o código foi revisado, executado e validado (`flutter analyze` sem *issues* e **38 testes passando**). As decisões de arquitetura (offline-first como *single source of truth*, fila FIFO, Cubit, `Either`) foram conduzidas por mim.

> O diferencial de IA **dentro do app** (categoria/resumo) é descrito na seção anterior e é independente desta declaração.

---

## 🔭 O que eu faria diferente com mais tempo

- **Reconciliação de conflitos:** hoje o último write vence. Com mais tempo, adicionaria *updatedAt* do servidor + estratégia de merge/conflito e *backoff* exponencial com teto de *retries* (as colunas `retry_count` e `last_error` já existem para isso).
- **Sincronização incremental real:** buscar apenas o *delta* (por `updatedAt`) em vez de repaginar; e unificar a paginação remota com itens locais pendentes de forma mais fina (hoje itens só-locais aparecem no topo do cache).
- **Migrações de schema versionadas** e testes de migração do SQLite.
- **WorkManager / background fetch** para sincronizar mesmo com o app fechado.
- **Camada de localização (l10n)** com `flutter_localizations`/ARB — hoje os textos são pt-BR diretos.
- **Testes de widget e de integração (e2e)** das telas, além dos unitários; e *golden tests* para o whitelabel.
- **CI** (GitHub Actions) rodando `analyze` + `test` + cobertura a cada push.
- **Refresh token / expiração** de sessão e *interceptor* de 401 com logout automático.
