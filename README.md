# SpendWise Pro 💳 — Modern Personal Finance App

SpendWise Pro is a high-performance, minimalist personal finance and micro-budgeting mobile application built using the **Flutter framework** and **Dart programming language**. Designed for seamless daily expense tracking, the application combines real-time state management, secure persistent local storage, and advanced user interaction patterns like bulk record management.

Unlike complex enterprise accounting software, SpendWise Pro focuses on consumer utility, offering an intuitive interface that allows users to manage their cash-in and cash-out operations with zero training.

---

## 🚀 Key Architectural Features

### 1. Persistent Local Database System 💾
* **Mechanism:** Integrated `shared_preferences` package to execute asynchronous read/write operations directly on the device's native local storage.
* **Data Serialization:** Transactions are structured as Dart Maps, serialized into stringified **JSON payloads**, and cached securely. 
* **Lifecycle Preservation:** The application triggers an automated database fetch during the `initState()` lifecycle phase, ensuring user data persists flawlessly across app terminations and device reboots.

### 2. Multi-Select Batch Deletion 🗑️
* **Contextual UI:** Long-pressing any transaction tile dynamically toggles the application into an **Action-Driven Selection Mode**.
* **State Synchronization:** The `AppBar` automatically mutates to display real-time selection metrics (e.g., "3 Selected") and exposes global deletion controls.
* **Efficient Disposal:** Implements batch removal queries against the core state array before overwriting the cached JSON database, delivering crisp $O(1)$ to $O(N)$ execution performance.

### 3. Real-Time Metric Scoreboard & Filters 🔍
* **Computed Getters:** Dynamically aggregates total credits and debits on the fly using Dart functional programming array-folding operations (`.fold()`).
* **Instant Query Wheels:** Contextual ChoiceChips instantly isolate the rendering tree to display 'All', 'Income', or 'Expense' entries without requiring network latency or heavy layout recalculations.

---

## 🛠️ Technical Tech Stack

* **Framework:** Flutter (Cross-Platform Engine)
* **Language:** Dart (Object-Oriented, Sound Static Typing)
* **Storage Architecture:** Native Key-Value SharedPreferences Caching
* **Design Philosophy:** Human Interface Guidelines / Material Design 3

---

## 💻 Code Structure & Architecture

The project maintains a clean, highly readable single-view stateful architecture optimized for maintenance:

```text
lib/
└── main.dart   # Houses Application Entry, State Management, Local DB Service & UI Layout