Polygon Voting App — Quickstart

This workspace contains a minimal Flutter skeleton demonstrating WalletConnect (walletconnect_dart), web3dart integration with Alchemy, and a basic Solidity voting contract for deployment via Remix.

Workspace layout:
- flutter_project/: minimal Flutter app (lib/services includes wallet & web3 wrappers)
- contracts/: `Voting.sol` OpenZeppelin-based smart contract
- todolist.md: prioritized to-do checklist

Quick steps to run the Flutter app

1. Install Flutter SDK (latest stable) and Android toolchain.
2. Open `flutter_project` in VS Code or Android Studio.
3. Edit `flutter_project/lib/services/web3_service.dart` and replace `YOUR_ALCHEMY_API_KEY` with your Alchemy API key.
4. Run:

```powershell
cd c:\blockchainvoting\flutter_project
flutter pub get
flutter run -d emulator-5554
```

WalletConnect note:
- The demo uses `walletconnect_dart` to create a session and opens the wallet via URI using `url_launcher`.
- If you run on an emulator, ensure the wallet app can handle the deep link or test on a physical device with a mobile wallet installed.

Deploying the Solidity contract

1. Open `contracts/Voting.sol` in Remix IDE.
2. Compile with Solidity ^0.8.19 and make sure to import OpenZeppelin (Remix supports GitHub import paths).
3. Create an Alchemy app for Polygon mainnet or Mumbai (for testing) and copy the RPC URL.
4. In Remix, select Injected Provider - Metamask and ensure your wallet has the network and funds.
5. Deploy, then copy the contract address and ABI JSON for use in the Flutter app.

Next steps
- Implement WebSocket event subscriptions in `web3_service.dart` to listen for `VoteCast` events.
- Implement transaction payload creation in `wallet_service.dart` using the deployed contract ABI and `eth_sendTransaction` via WalletConnect.
- Add unit tests for the Solidity contract (Hardhat or Foundry preferred).

Security
- For production, use multisig for admin ops and consider a third-party audit.

