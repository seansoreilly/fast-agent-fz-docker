# Merchant Dashboard User Guide

This section provides a brief overview of functionalities available within the Fat Zebra Merchant Dashboard. While the primary focus of this corpus is the API, understanding the dashboard is helpful for configuration, reporting, and manual actions.

_(This section provides high-level pointers to dashboard features relevant to API integration. Refer to the official 'Merchant Dashboard User Guide' for detailed operational instructions.)_

## Overview

The Fat Zebra Merchant Dashboard is the web interface for managing your account, viewing transactions, configuring settings, and performing manual actions.

## Transactions

- **Search & View:** Find transactions processed via API or dashboard using references, IDs, dates, etc. View detailed status, response codes, and associated data (like metadata).
- **Manual Actions:** Perform actions like Refunds on transactions originally processed via API. Useful for exceptions or support scenarios.
- **Virtual Terminal:** Process manual card payments (MOTO). Not directly related to API integration but part of the overall payment capability.
- **Disputes:** Monitor and manage chargeback disputes.

## Reports

- **Transaction Reports:** Generate detailed reports on processed transactions (API and manual) for reconciliation.
- **Settlement Reports:** Track funds settled to your bank account.
- **Access:** View reports online or schedule email delivery.

## Customers

- **Token Management:** View stored customer payment methods (tokens created via API or SDK). May allow manual addition or deletion of tokens.
- **Payment Plans:** If Fat Zebra offers built-in recurring/subscription plans, this section allows managing them (potentially created via API or dashboard).

## Users `[API_AUTH]`

- **API Keys/Credentials:** This is the **critical section** for API integration. Here you will typically:
  - Generate your **API Username** and **API Token** required for [Basic Authentication](./getting-started.md#authentication).
  - Manage credentials for Sandbox and Production environments separately.
  - Potentially create restricted API keys with limited permissions.
- **User Management:** Invite team members, manage their permissions (e.g., API access vs. reporting only), and configure Multi-Factor Authentication (MFA) for dashboard login security.

## Direct Entries / Batches `[BATCH_FORMAT]`

- **Manual Upload:** Provides an interface to upload batch files (Purchase, Refund, Direct Debit) manually in the required format (usually CSV). _(See [Batches](./batches.md#uploading-batches))_
- **Results Download:** Access and download the result files for processed batches. _(See [Batches](./batches.md#result-files))_

## Settings / Configuration

- **Webhooks `[WEBHOOKS]`:** Configure your webhook endpoint URL(s) and select the event types to subscribe to. Obtain your **Webhook Secret** here for validation. _(See [Webhooks](./webhooks.md#handling-webhooks))_
- **Wallet Configuration `[WALLET:APPLE_PAY]` `[WALLET:GOOGLE_PAY]`:** Manage settings for Apple Pay (certificates, merchant IDs) and Google Pay integration. _(See [Wallets](./wallets.md))_
- **Security Settings:** Access PGP keys (if used), potentially configure fraud prevention rules, manage IP whitelisting (if applicable).
- **3DS2 Configuration `[3DS2]`:** Enable/disable 3D Secure 2 and potentially configure related rules.

---

_See also: [Getting Started](./getting-started.md), [Batches](./batches.md), [Webhooks](./webhooks.md)_
