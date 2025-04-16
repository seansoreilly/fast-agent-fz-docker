# Glossary of Terms `[GLOSSARY]`

This document defines key terms used within the Fat Zebra documentation and API.

_(Definitions need to be extracted from the 'Glossary' page content for Fat Zebra specifics)_

- **Acquirer (Acquiring Bank):**
  - The financial institution that processes credit/debit card payments on behalf of a merchant and routes them through the card networks (Visa, Mastercard) to the issuer.
- **Authorization (Auth):**
  - The process where a transaction is sent to the cardholder's bank (issuer) to verify the availability of funds or credit. An approved authorization places a temporary hold on the funds but doesn't transfer them.
- **Capture:**
  - The process following authorization where the merchant confirms the transaction, triggering the transfer of funds from the issuer to the acquirer (and ultimately to the merchant during settlement).
- **Settlement:**
  - The process where captured funds are actually transferred from the issuing bank, through the card network and acquirer, to the merchant's bank account. This typically happens in batches.
- **Chargeback:**
  - A transaction reversal initiated by the cardholder's bank (issuer) usually due to a dispute filed by the cardholder (e.g., didn't receive goods, unauthorized charge).
- **MID (Merchant ID):**
  - A unique identifier assigned by the acquiring bank to a merchant account, used for routing and identifying transactions.
- **TID (Terminal ID):**
  - A unique identifier assigned to a specific point of interaction (physical terminal or virtual/e-commerce setup) under a Merchant ID.
- **Token / Tokenization:**
  - The process of replacing sensitive data (like a Primary Account Number - PAN) with a non-sensitive equivalent, referred to as a token. This token can be stored and used for future transactions without exposing the original PAN. _(See also: [Card On File](./card-on-file.md))_
- **PAN (Primary Account Number):**
  - The main number identifying a payment card (typically 14-19 digits).
- **CVV / CVC (Card Verification Value / Code):**
  - The 3 or 4-digit security code usually found on the back of a payment card, used to verify the card is physically present during card-not-present transactions.
- **AVS (Address Verification System):**
  - A system used to verify the cardholder's billing address provided during a transaction against the address on file with the issuing bank. _(See also: [Purchases](./purchases.md#avs))_
- **3D Secure (3DS):**
  - A security protocol (versions 1 and 2) designed to provide an additional layer of authentication for online card transactions, often involving a challenge step for the cardholder. _(See also: [3DS2 Integration](./3ds2.md))_
- **Webhook:**
  - An automated message sent from an application (Fat Zebra) to another (your server) via an HTTP POST request when a specific event occurs, enabling real-time notifications. _(See also: [Webhooks](./webhooks.md))_
- **Direct Debit:**
  - An instruction from a customer to their bank authorizing an organization (the merchant) to collect payments directly from their bank account. _(See also: [Direct Entries](./direct-entries.md))_
- **Direct Credit:**
  - A method of making payments directly into a payee's bank account (e.g., payouts, refunds to bank accounts). _(See also: [Direct Entries](./direct-entries.md))_
- **Issuer (Issuing Bank):**
  - The financial institution that issued the payment card to the cardholder.
- **Card Scheme:**
  - The payment networks that facilitate transactions between issuers and acquirers (e.g., Visa, Mastercard, American Express).
- **MOTO (Mail Order / Telephone Order):**
  - Transactions initiated remotely via mail or telephone where the card is not physically present.

_See also: [Getting Started](./getting-started.md)_
