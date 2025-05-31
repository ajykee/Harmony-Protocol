# 🎵 Harmony Protocol

**A Creative Approach to Music Rights Management on the Blockchain**
Built with Clarity on the Stacks blockchain.

## Overview

**Harmony Protocol** empowers musicians and listeners through a decentralized system for music rights, royalties, and revenue sharing. Artists can tokenize song ownership, collaborate with others, reward listeners, and earn streaming revenue — all transparently on-chain.

---

## ✨ Features

* 🎶 **Tokenized Songs**: Artists can mint songs with fractional shares.
* 🤝 **Collaborator Management**: Assign collaborators with customizable royalty percentages (up to 50% per person, max 5 collaborators).
* 💸 **Share Marketplace**: Listeners and investors can purchase shares in songs.
* 📈 **Streaming Royalties**: Simulate streaming activity and distribute earnings to shareholders.
* 🧾 **Listener Rewards**: Track streams and reward active listeners.
* 🔐 **Song Locking**: Lock metadata and collaborators once finalized.
* 🧑‍💼 **Admin Tools**: Adjust platform fees and withdraw earnings.

---

## 🧱 Data Structures

### Constants

* `contract-owner`: Initial deployer (admin).
* Various error codes (`err-owner-only`, `err-not-found`, etc.) for safe and clear contract behavior.

### Data Variables

* `song-counter`: Tracks song IDs.
* `platform-fee-percentage`: Platform cut (default: 2.5%).

### Key Maps

* `songs`: Stores song metadata and financials.
* `song-collaborators`: Royalty splits for contributors.
* `shareholder-balances`: Share ownership per song.
* `listener-rewards`: Tracks streaming activity per user.
* `artist-stats`: Per-artist performance and verification.
* `total-platform-fees`: Accumulated fees for the protocol.

---

## 🔧 Public Functions

### 🎼 Song Lifecycle

* `create-song(title, total-shares, share-price)`: Mint a new song.
* `add-collaborator(song-id, collaborator, percentage)`: Assign collaborators.
* `lock-song(song-id)`: Prevent further changes to a song.

### 💵 Share & Revenue Management

* `buy-shares(song-id, amount)`: Purchase shares in a song.
* `stream-song(song-id, revenue-amount)`: Simulate a stream and accumulate royalties.
* `claim-royalties(song-id)`: Shareholders claim earned streaming revenue.

### 📊 View-Only Queries

* `get-song-info(song-id)`
* `get-shareholder-balance(song-id, holder)`
* `get-artist-stats(artist)`
* `get-listener-rewards(listener, song-id)`
* `get-platform-fees()`

### 🛠️ Admin Functions

* `update-platform-fee(new-fee)`: Adjust platform cut (max 10%).
* `withdraw-platform-fees(amount)`: Withdraw accumulated platform revenue.

---

## 🚦 Royalty Distribution

Royalties accumulate through `stream-song` calls and are distributed once a **1 STX threshold** is reached. Distribution currently assumes simplified logic but can be extended to iterate all shareholders for real-time, on-chain payouts.

---

## 🔒 Security Notes

* Only artists can modify their songs and add collaborators.
* Once locked, a song cannot be edited.
* Platform fees are adjustable only by the contract owner.
* Contract follows a fail-fast design with strict error handling.

---

## 🧪 Example Use Case

1. **Alice creates a song** with 1,000 shares priced at 1 STX each.
2. She **adds Bob and Carol** as collaborators with 20% and 10% royalties.
3. Users **buy shares** in the song, contributing STX.
4. As the song gets streamed, **revenue is simulated** via `stream-song`.
5. Once revenue passes the threshold, shareholders **claim their share** via `claim-royalties`.

---

## 🧱 Tech Stack

* **Language**: [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-language)
* **Platform**: [Stacks Blockchain](https://stacks.co/)
* **Compatible Wallet**: Hiro Wallet

---

## 📜 License

MIT License — Free to use, fork, and remix with attribution.

---

## 🙋 Contributing

Pull requests welcome! For major changes, open an issue first to discuss what you'd like to change or improve.

---

## 📬 Contact

* Protocol Maintainer: `tx-sender`
* Built for decentralized music lovers and creators 🌍🎧

