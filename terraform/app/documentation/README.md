# Fat Zebra API Knowledge Corpus

This directory contains a structured knowledge corpus derived from the Fat Zebra API documentation (`https://docs.fatzebra.com/docs/*`).

**Purpose:**

- To provide a context source for Large Language Models (LLMs) interacting with the Fat Zebra API via protocols like the Model Context Protocol (MCP).
- To enable an LLM-powered chatbot to answer user questions about the Fat Zebra API and platform.

**Structure:**

The corpus is divided into Markdown files, mirroring the main sections of the official documentation:

- [Getting Started](./getting-started.md): Core concepts, authentication, endpoints, errors.
- [Pagination](./pagination.md): API pagination details.
- [Glossary](./glossary.md): Definitions of key terms.
- [Testing](./testing.md): Test card numbers and sandbox information.
- [Purchases](./purchases.md): Purchase API endpoint, request/response, codes, metadata, etc.
- [Card On File](./card-on-file.md): Tokenization, recurring payments, MIT.
- [Direct Entries](./direct-entries.md): Direct Debits and Credits API.
- [Batches](./batches.md): Batch file processing.
- [Persisted Invoices](./persisted-invoices.md): Invoice upload specification.
- [Wallets](./wallets.md): Apple Pay and Google Pay integration.
- [Webhooks](./webhooks.md): Handling webhook events.
- [Network Token Passthrough](./network-token-passthrough.md): Using your own network tokens.
- [Security](./security.md): PCI compliance and security practices.
- [SDKs](./sdk.md): Information on available SDKs (React, Javascript).
- [3DS2 Integration](./3ds2.md): 3D Secure 2 details.
- [Merchant Dashboard](./merchant-dashboard.md): Guide for using the merchant dashboard (Note: Less API-focused, may be summarized differently).
