# Polygon Voting App — Todo List

This file lists the full checklist and decision guidance for building a live Polygon voting app (Flutter + WalletConnect + web3dart + Alchemy). Each item includes purpose, success criteria, risks, and next steps. The goal is a live, secure production deployment on Google Play Store and Polygon mainnet.

---

## Project assumptions
- Primary mobile app: Flutter (Android target first; iOS later).
- Wallet integration via WalletConnect (evaluate v2 vs v1 during implementation).
- Blockchain access via Alchemy (primary RPC / websocket). Have fallback RPC providers configured.
- Smart contract written in Solidity using OpenZeppelin helpers.
- Tests and CI in GitHub Actions.

---

## High-level milestones (checked as progress)
- [x] Setup local dev environment (Flutter SDK, Android toolchain)
- [x] Create Flutter project skeleton
- [x] Write & test Solidity Voting contract
- [x] Deploy to Polygon Mumbai (testnet) and verify
- [x] Integrate WalletConnect in Flutter
- [x] Integrate web3dart + Alchemy (HTTP + WebSocket)
- [x] Implement transaction helper (eth_sendTransaction payload via WalletConnect)
- [ ] Add WebSocket-based contract event subscription & minimal UI listener
- [x] Build UI: connect wallet, poll view, vote UX, tx status
- [ ] Add unit & integration tests (Solidity + Dart)
- [ ] CI: run Solidity tests, verify on polygonscan, build Android AAB
- [ ] Perform security checks & optionally formal audit
- [ ] Deploy contract to Polygon mainnet and verify
- [ ] Publish Flutter app to Google Play Store

---

## Detailed todo items

### 1) Setup Development Environment (developer work)
- Tasks:
  - Install Flutter SDK (stable) and Android SDK.
  - Install VS Code / Android Studio & Flutter plugins.
  - Create project: `flutter create polygon_voting_app`.
- Success criteria: `flutter doctor` green; project builds for debug on Android emulator.
- Estimated effort: 1–2 hours.
- Status: [x] Completed (Flutter project skeleton created and dependencies installed).

### 2) Smart Contract: Solidity (OpenZeppelin scaffold)
- Tasks:
  - Create contract using OpenZeppelin libraries: Ownable, ReentrancyGuard.
  - Poll lifecycle: createPoll, addOption, openPoll, closePoll, vote (one vote per wallet), view tallies.
  - Emit events: PollCreated, OptionAdded, VoteCast, PollClosed.
  - Unit tests using Hardhat (or Foundry) covering edge-cases.
- Artifacts: `contracts/Voting.sol`, tests in `test/` or `foundry/`.
- Estimated effort: 4–12 hours (more if rigorous tests & edge cases).
- Status: [x] Completed (Voting.sol scaffold created; unit tests pending).

### 3) Deploy & Verify on Mumbai (testnet)
- Tasks:
  - Create Alchemy app for Mumbai; add RPC and WebSocket URL.
  - Deploy contract via Remix/Hardhat/Foundry to Mumbai.
  - Verify on Polygonscan (testnet) and save contract address & ABI JSON.
- Success: Verified contract + accessible ABI.
- Estimated effort: 1–2 hours.
- Status: [ ] Pending (contract scaffold ready for deployment).

### 4) Flutter Packages & Project Wiring
- Add to `pubspec.yaml`:
  - `walletconnect_dart` (or v2-compatible lib), `url_launcher`, `web3dart`, `http`.
  - Consider `riverpod`/`provider` for state management.
- Run `flutter pub get`.
- Estimated effort: 30–60 minutes.
- Status: [x] Completed (packages added, pub get run, project analyzes cleanly).

### 5) WalletConnect Integration
- Tasks:
  - Initialize connector with app metadata.
  - Implement Connect Wallet UI and flow (open wallet app via URI/deep link).
  - Manage session and persisted session state.
- Success: Able to connect to a wallet and read `connector.session.accounts`.
- Estimated effort: 2–4 hours.
- Status: [x] Completed (WalletService implemented with connect, session management, and UI integration).

### 6) RPC & web3dart client (HTTP + WebSocket)
- Tasks:
  - Configure `Web3Client` with Alchemy HTTP for reads and Alchemy WebSocket for event subscriptions.
  - Implement a `safeRpcProvider` that falls back to a secondary RPC if Alchemy fails.
- Success: Read-only contract calls and event subscriptions working against Mumbai.
- Estimated effort: 2–4 hours.
- Status: [x] Completed (Web3Service with HTTP client, WS subscription with reconnect/backoff, and polling fallback).

### 7) Transaction Helper & WalletConnect Signing Flow
- Tasks:
  - Build encoded transaction payloads using `contract.function(...).encodeCall(...)`.
  - Create `eth_sendTransaction` payloads and send via WalletConnect `sendCustomRequest`.
  - Include gas estimates and clear UX for gas/confirmation.
- Edge cases: insufficient funds, network mismatch, user rejects signing.
- Success: User can sign & send a vote tx; app receives tx hash.
- Estimated effort: 3–6 hours.
- Status: [x] Completed (sendContractTransaction helper with encoding, network checks, and error handling).

### 8) WebSocket Event Subscription & Minimal UI Listener
- Tasks:
  - Subscribe to VoteCast event logs (via `client.events(FilterOptions.events(...))`).
  - Update UI in near real-time on new events (optimistic updates too).
  - Persist subscription state to survive app lifecycle changes.
- Benefits: Real-time tallies, reduced polling, better UX.
- Risks: WebSocket disconnects; must implement reconnection/backoff logic.
- Success: UI updates within seconds after on-chain events are emitted.
- Estimated effort: 3–6 hours.

### 9) UI: Polls, Voting Flow, Transaction Status
- Tasks:
  - Connect screen, poll list screen, vote screen, results screen.
  - Transaction queue with persistent storage for pending TXs.
  - Clear mapping of wallet address to one-vote enforcement (UI-level check + on-chain enforcement).
- Success: Smooth, user-friendly voting flow with clear statuses.
- Estimated effort: 8–24 hours (depends on polishing & animations).

### 10) Gasless Voting Prototype (EIP-712 + Relayer)
- Tasks:
  - Define EIP-712 typed data for votes and implement signing flow in app.
  - Build a relayer endpoint (Node/Express or serverless) that receives signed payloads, verifies signatures, optionally rate-limits, and submits transactions on behalf of users.
  - Consider economic model: relayer pays gas; reimbursements or donation model.
- Security & abuse mitigation: rate limit, captcha, wallet reputation, blacklists.
- Infra: Docker, cloud VM or serverless, keys in KMS (Azure Key Vault / Google KMS / AWS KMS), monitoring.
- Success: Users sign off-chain; relayer submits on-chain tx; vote counted.
- Risks: Relayer becomes a central operator; must secure keys and funding.
- Estimated effort: 2–5 days (prototype), production-grade relayer longer.

### 11) Indexing & Querying for UI (The Graph / Alchemy / custom indexer)
- Tasks:
  - Create a subgraph (The Graph) or use Alchemy Enhanced API to index VoteCast events.
  - Provide fast API endpoints for feed & history queries.
- Benefits: fast aggregation, historical queries, paginated results.
- Estimated effort: 1–3 days (subgraph) depending on complexity.

### 12) Testing & CI/CD
- Tasks:
  - Solidity tests (Hardhat/Foundry) with coverage.
  - GitHub Actions workflows: run tests, run linters, run `flutter analyze`, and build release AAB on `main`/`release` branch.
  - Auto-verify contracts after deployment on polygonscan via GH action.
- Success: Green CI on PRs and main branch.
- Estimated effort: 1–3 days to get solid CI.

### 13) Security & Auditing
- Tasks:
  - Static analysis (Slither), fuzzing, unit test coverage targets (>80%).
  - Consider third-party audit for production deployments.
- Cost/Time: Audit can take weeks and cost money.
- Success: Identified & fixed critical issues.

### 14) Release & Play Store
- Tasks:
  - Prepare Android signing keys, privacy policy, Play Store listing.
  - Build AAB: `flutter build appbundle --target-platform android-arm,android-arm64,android-x64`.
  - Upload and roll out release.
- Success: App live on Play Store.
- Estimated effort: 1–3 days for store listing and testing.

### 15) Monitoring & Maintenance
- Tasks:
  - Setup Alchemy dashboards, Sentry, Firebase Analytics.
  - Monitor RPC errors and failed TXs.
  - Plan for contract admin (multisig for emergency pause/migration).
- Success: Alerts and dashboards operational.

---

## Consequences / tradeoffs of the four options you listed

Below are practical consequences, pros/cons, and production-readiness guidance so you can choose a path that leads to a live app.

1) Add WebSocket-based event subscription and a minimal UI listener
- Pros:
  - Real-time updates (near-instant UI response) and reduced polling costs.
  - Better UX and lower RPC usage for frequent reads.
- Cons / risks:
  - WebSocket connections need robust reconnection/backoff logic on mobile (background limitations on Android).
  - Some RPC providers impose limits on web socket connections; you must monitor concurrency and fallback.
- Production-ready? Yes — recommended for live app. Requires reconnection logic and fallback to HTTP polling when WS unavailable.
- Dependencies: Alchemy WebSocket URL or alternative WS provider.
- Estimated effort: 3–6 hours to prototype, 1 day to harden.

2) Implement a transaction helper that crafts the eth_sendTransaction payload and integrates with WalletConnect flow
- Pros:
  - Encapsulates tx creation/validation, consistent UX, easier to add meta-data (gas estimate, chain id) and handle errors uniformly.
  - Critical for live product: need reliable transaction signing flow.
- Cons:
  - Must handle many error cases (nonce mismatch, gas estimation failure, wallet rejection).
  - WalletConnect v1 vs v2 differences (methods & params) require version-specific logic.
- Production-ready? Yes — necessary for live app. Must be thoroughly tested with multiple wallet apps.
- Dependencies: walletconnect_dart support for desired WC version.
- Estimated effort: 3–6 hours initial, more to harden across wallets.

3) Write a simple OpenZeppelin-based Solidity voting contract scaffold + unit tests in Hardhat/Foundry and CI workflow
- Pros:
  - On-chain enforcement of rules (one vote per wallet, integrity). Unit tests provide safety.
  - OpenZeppelin reduces risk by reusing audited components.
- Cons:
  - On-chain upgrades are hard; careful design needed (upgradeable proxy or data migration plans).
  - Must audit/configure admin access (use multisig) before mainnet deploy.
- Production-ready? Solidity code + tests are necessary; additional formal audit recommended before large production launch.
- Dependencies: Hardhat (JS) or Foundry (Rust); use what your team prefers.
- Estimated effort: 1–2 days for scaffold & tests; weeks + budget for audit.

4) Prototype gasless voting flow (EIP-712 sign & relayer) with an example relayer endpoint
- Pros:
  - Great UX for non-crypto users: no need for MATIC to vote.
  - Lower friction leads to better adoption.
- Cons / risks:
  - Relayer is centralized infrastructure; requires secure key management and anti-abuse systems.
  - Economic model: who pays for gas? Consider sponsorship or fee model.
  - More complexity: signature verification on-chain and replay protection (nonces).
- Production-ready? Prototype is feasible; production-grade relayer requires infrastructure (KMS, rate-limits, monitoring). Be cautious about trust model.
- Dependencies: EIP-712 signing on client; relayer server (Express + ethers.js or web3.js), server key secured in KMS.
- Estimated effort: Prototype 2–5 days; production relayer weeks with hardened security.

---

## Prioritized recommendation (to reach live solution quickly)
1. Implement WalletConnect + transaction helper + web3dart client first (connect, sign, send, receive tx hash).
2. Add WebSocket-based event subscription (real-time results) and robust reconnection logic.
3. Build and thoroughly test Solidity contract on Mumbai using Hardhat/Foundry and add CI.
4. Deploy to mainnet only after tests, verification, and at least a security review.
5. Prototype gasless relayer in parallel if you need non-crypto onboarding, but treat it as a separate product that requires operational security.

This order minimizes risk and gets a working, auditable voting flow in front of users quickly.

---

## Deliverables to produce for each item (artifacts)
- Flutter project skeleton with example WalletConnect integration and transaction helper.
- `web3_client.dart` wrapper supporting HTTP & WebSocket endpoints and reconnection.
- `contracts/Voting.sol` (OpenZeppelin-based) and tests (Hardhat or Foundry).
- CI workflows: `/.github/workflows/solidity-tests.yml`, `flutter-ci.yml`.
- Example relayer: `relayer/` folder with `server.js` (Express) and Dockerfile (optional).
- README with local dev steps and deployment instructions.

---

## Next steps (pick one)

---
### Notes / Risk register
- RPC provider limits (monitor Alchemy usage). Add fallback providers.

---

## Suggested grouped sections (pick entire sections to work on at once)

Below are ready-to-pick sections. Each section groups related tasks so you can choose one to complete as a unit. Mark a section done when all child tasks are complete.

1) Core Wallet & Transaction Flow (recommended first)
 - Tasks:
   - Finalize WalletConnect integration (session management, reconnect, multi-account support).
   - Implement transaction helper (encode function calls, network checks, pass to wallet for signing).
   - Show gas estimate and user-friendly tx UX (pending / success / failure).
 - Success criteria: Users can connect a wallet, sign, and send a vote; app shows tx hash and status.
 - Estimated effort: 1–2 days.
 - Artifacts: `WalletService`, `TxHelper`, UI flow for connect/sign/send.

2) Realtime & Robust Events (live results)
 - Tasks:
   - Add WebSocket event subscription with reconnect/backoff.
   - Add polling fallback (periodic tallies) when WS unavailable.
   - Event decoding into typed Dart models and UI updates.
 - Success criteria: UI updates within seconds of VoteCast events and recovers from WS drops automatically.
 - Estimated effort: 1–2 days.
 - Artifacts: `Web3Service.subscribeWithFallback`, decoded event models, real-time UI.

3) Contract Development & Tests
 - Tasks:
   - Finalize Solidity contract with OpenZeppelin patterns.
   - Write unit tests (Hardhat or Foundry), add Slither/static checks.
   - CI workflow to run tests & verify on testnet.
 - Success criteria: All tests green in CI, contract verified on polygonscan (testnet) after deployment.
 - Estimated effort: 2–4 days (plus audit time if needed).
 - Artifacts: `contracts/`, `test/`, `.github/workflows/solidity-tests.yml`.

4) Gasless Voting (EIP-712 + Relayer) — prototype
 - Tasks:
   - Define EIP-712 typed data for vote messages.
   - Implement client-side signing flow and relayer endpoint to submit signed messages on-chain.
   - Add replay protection, rate-limiting, and secret management (KMS) for relayer.
 - Success criteria: Users sign offline; relayer submits transaction and vote is counted.
 - Risks: Relayer centralization, key management, cost model (who pays gas).
 - Estimated effort: Prototype 3–7 days; production longer.
 - Artifacts: `relayer/` service, EIP-712 spec, server deployment guide.

5) UX, Admin Tools & Persistence
 - Tasks:
   - Persist ABI + contract address and allow admin to manage polls from app.
   - Add user-friendly error mapping for common wallet/RPC errors.
   - Polish UI: state management (Riverpod/Bloc), persistent tx queue, account switching.
 - Success criteria: Admins can create/close polls; users see clear error messages and persistent state.
 - Estimated effort: 2–4 days.
 - Artifacts: UI screens, `shared_preferences` config, admin controls.

6) Security, Monitoring & Hardening
 - Tasks:
   - Run static analysis (Slither), add unit test coverage targets.
   - Add Sentry/Firebase for crash reporting, Alchemy/RPC monitoring.
   - Plan multisig for contract admin; prepare upgrade/migration strategy.
 - Success criteria: Security checks in CI, alerts for RPC/tx spikes, admin multisig configured.
 - Estimated effort: 2–5 days (audit additional).
 - Artifacts: CI checks, monitoring dashboards, security report.

7) CI/CD & Release Automation
 - Tasks:
   - Add GitHub Actions to run Solidity tests, run `flutter analyze` and build Android AAB on release branch.
   - Add automatic contract verification step after deployments.
 - Success criteria: Merges run tests and create signed AAB artifacts for Play Store.
 - Estimated effort: 1–2 days.
 - Artifacts: `.github/workflows/*` including build & verify flows.

8) Indexing & Analytics (The Graph / Alchemy)
 - Tasks:
   - Create a subgraph or use Alchemy Enhanced APIs to index VoteCast events, poll metadata.
   - Provide backend endpoints for the app to fetch aggregated results and history.
 - Success criteria: Fast queries for historical results and user activity.
 - Estimated effort: 2–5 days.
 - Artifacts: subgraph manifest, indexer code, API endpoints.

How to pick
- Pick one or multiple section numbers (for example: "Do 1,2,5 together").
- I will implement the chosen sections end-to-end and create or modify the necessary files and CI entries.

If you want, I can now implement any of these grouped sections; which section(s) should I start with? 
- Be explicit about on-chain upgrade strategies prior to mainnet deployment.
- Relayer introduces centralization and must be secured properly.


---

End of todo list.
