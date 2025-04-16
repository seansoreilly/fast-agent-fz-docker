# Webhooks `[WEBHOOKS]`

This section describes how to use webhooks to receive real-time notifications about events happening in your Fat Zebra account.

## Overview

_(High-level description of webhooks and their benefits needs to be extracted from the 'Webhooks > Overview' page)_

Webhooks allow Fat Zebra to send automated messages (HTTP POST requests) to your application's endpoint when specific events occur (e.g., a purchase succeeds, a direct debit fails, a card is updated). This avoids the need for constant polling of the API.

## Handling Webhooks

_(Verify details against official 'Handling Webhooks' documentation)_

1.  **Create an Endpoint:** Develop an API endpoint (URL) on your server that is publicly accessible via HTTPS. This endpoint must be capable of receiving HTTP POST requests with a JSON body.
2.  **Configure in Dashboard:** Log in to your Fat Zebra Merchant Dashboard. Navigate to the Webhooks or Developer settings section. Add a new webhook endpoint, providing your HTTPS URL and selecting the specific event types you want to subscribe to (e.g., `purchase.succeeded`, `direct_debit.failed`). You will likely obtain a **Webhook Secret** during this setup - store it securely.
3.  **Receive Events:** Your endpoint will receive POST requests from Fat Zebra IPs whenever a subscribed event occurs. The request body will be JSON containing the event details (see Events section below).
4.  **Validate Requests (CRITICAL):** **Always validate incoming webhooks** to ensure they originated from Fat Zebra and haven't been tampered with. The common method is using a signature header:

    - **Signature Header:** Fat Zebra likely includes a signature in an HTTP header, e.g., `X-FZ-Signature` or `Webhook-Signature`.
    - **Secret:** Use the **Webhook Secret** obtained during setup.
    - **Validation Logic:** The signature is typically an HMAC (e.g., HMAC-SHA256) of the raw request body (JSON string), computed using the Webhook Secret as the key. Calculate the expected signature on your server using the received request body and your secret, then compare it securely (using a constant-time comparison function) against the signature provided in the header. Reject any request where the signature does not match.

      ```python
      # Example Python/Flask validation (Illustrative)
      import hmac
      import hashlib
      from flask import Flask, request, abort

      app = Flask(__name__)
      WEBHOOK_SECRET = b'YOUR_FATZEBRA_WEBHOOK_SECRET' # Use bytes

      @app.route('/webhook-receiver', methods=['POST'])
      def handle_webhook():
          signature_header = request.headers.get('X-FZ-Signature') # Confirm header name
          if not signature_header:
              abort(400, 'Missing signature header')

          payload = request.get_data() # Raw body as bytes
          expected_signature = hmac.new(WEBHOOK_SECRET, payload, hashlib.sha256).hexdigest()

          if not hmac.compare_digest(signature_header, expected_signature):
              abort(403, 'Invalid signature')

          # Signature verified, process the event (asynchronously recommended)
          event_data = request.get_json()
          print(f"Received valid event: {event_data.get('event')}")
          # --- Add to a queue for async processing ---

          return '', 200 # Respond immediately with 200 OK
      ```

5.  **Respond Quickly (200 OK):** Acknowledge receipt of the webhook by returning an HTTP `200 OK` status code **within a few seconds (e.g., < 5 seconds)**. Do **not** perform lengthy processing (database updates, external API calls, email sending) before responding. If Fat Zebra doesn't receive a `200 OK` quickly, it will consider the delivery failed and may retry.
6.  **Process Asynchronously:** Handle the actual business logic triggered by the webhook event (updating order status, sending emails, etc.) in a background job or queue system after sending the `200 OK` response.
7.  **Handle Failures/Retries:** If your endpoint returns a non-`2xx` status code or times out, Fat Zebra will typically retry sending the webhook several times with increasing delays (e.g., over minutes, then hours - _confirm retry schedule_). Ensure your endpoint is idempotent (processing the same event multiple times doesn't cause duplicate actions) as retries can occur.
8.  **Monitor:** Monitor your webhook endpoint for failures and the Fat Zebra Dashboard for delivery statuses.

## Events `[WEBHOOK_EVENT]`

_(List of available event types and example payloads need to be extracted from the 'Events' page and sub-pages)_

Fat Zebra sends webhooks for various events. You can typically select which events you want to subscribe to in the dashboard.

**Common Event Types:**

- `purchase.succeeded`: A card purchase was successfully authorized/captured.
- `purchase.failed`: A card purchase failed.
- `refund.succeeded`: A refund was processed successfully.
- `refund.failed`: A refund attempt failed.
- `direct_debit.cleared`: A direct debit has cleared.
- `direct_debit.failed`: A direct debit failed (e.g., insufficient funds, invalid account).
- `card.updated`: A tokenized card's details were updated (e.g., expiry).
- _(List other relevant event types, e.g., dispute events, subscription events)_

**Example Payload (`purchase.succeeded` - Illustrative):**

_(Example JSON payload needs to be extracted from 'Example Webhooks' page)_

```json
{
  "event": "purchase.succeeded",
  "payload": {
    "successful": true,
    "authorized": true,
    "captured": true,
    "id": "txn_xxxxxxxxxxxx",
    "amount": 1000,
    "currency": "AUD",
    "reference": "YourReference123",
    "message": "Approved",
    "response_code": "00",
    "transaction_time": "...",
    "card": {
      "holder": "...",
      "number": "411111...1111",
      "scheme": "Visa",
      "token": "tok_...",
      "expiry_month": 12,
      "expiry_year": 2029
    },
    "metadata": {
      "order_id": "SO-987"
    }
    // ... other relevant fields ...
  },
  "webhook_id": "wh_...",
  "timestamp": "..."
}
```

---

_See also: [Getting Started](./getting-started.md), [Purchases](./purchases.md), [Direct Entries](./direct-entries.md)_
