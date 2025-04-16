# Security

This section covers security aspects related to integrating with Fat Zebra, particularly PCI DSS compliance.

## Overview

_(Verify details against official 'Security > Overview' documentation)_

Security is a shared responsibility. Fat Zebra provides secure infrastructure, but you must also secure your integration and systems.

- **HTTPS:** All API communication MUST occur over HTTPS (TLS 1.2 or higher recommended).
- **API Credentials:** Keep your API Username and Token confidential. Do not embed them directly in client-side code. Use secure server-side storage.
- **Webhook Validation:** Always validate incoming webhooks using the provided signature and secret. _(See [Webhooks](./webhooks.md#handling-webhooks))_
- **PCI DSS:** Understand your PCI DSS compliance requirements based on your integration method (see below).
- **Data Minimization:** Only collect and store the cardholder data necessary for your processing needs.

## PCI Certification & Compliance

_(Verify details against official 'PCI Certification' and 'What is PCI Compliance' documentation)_

- **Fat Zebra's Status:** Fat Zebra is certified as a **PCI DSS Level 1 Service Provider**, the highest level of compliance.
- **What is PCI DSS:** The Payment Card Industry Data Security Standard is a global standard with technical and operational requirements for protecting cardholder data. Compliance is mandatory for all entities that store, process, or transmit cardholder data.
- **Your Responsibility & SAQ Type:** Your specific compliance requirements, and the Self-Assessment Questionnaire (SAQ) you need to complete, depend on how you handle cardholder data:
  - **SAQ A:** Applies if you fully outsource all cardholder data functions to Fat Zebra, and your website only contains a redirect/link to Fat Zebra's hosted payment page (HPP). Card data never touches your systems.
  - **SAQ A-EP:** Applies if your website doesn't directly handle card data, but it **does affect the security** of the transaction (e.g., you provide the checkout page where Fat Zebra's JS SDK or iframe elements are embedded). This is common when using client-side tokenization via SDKs.
  - **SAQ D (Merchants & Service Providers):** Applies if your systems **store, process, or transmit** cardholder data (PAN, CVV, etc.). This includes server-to-server API integrations where you send raw card details from your backend to Fat Zebra. This SAQ has the most extensive requirements.
  - **Tokenization Impact:** Using Fat Zebra's [tokenization](./card-on-file.md) via client-side SDKs (typically SAQ A-EP) or receiving tokens back from purchases is crucial for **reducing your PCI scope**. Storing only tokens (and not PANs) significantly simplifies compliance compared to SAQ D.
- **Recommendation:** Minimize your PCI scope by using Fat Zebra's hosted solutions (HPP) or client-side SDKs ([JS](./sdk.md#javascript-sdk), [React](./sdk.md#react-sdk)) whenever possible. Avoid letting raw cardholder data touch your server environment.

## PGP Key

_(Information about Fat Zebra's PGP key and its usage needs to be extracted from the 'PGP Key' page)_

- **Purpose:** Fat Zebra may provide a PGP public key for securely encrypting sensitive information sent via less secure channels (e.g., certain batch files, specific support communications).
- **Key Availability:** _(Where to find the key - e.g., link on the page, downloadable file)_
- **Usage:** _(How to use the key for encrypting data)_

---

_See also: [Getting Started](./getting-started.md), [Card On File](./card-on-file.md), [SDKs](./sdk.md)_
