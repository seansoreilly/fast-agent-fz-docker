# Getting Started with the Fat Zebra API

This section covers the fundamental concepts for interacting with the Fat Zebra REST API.

**Core Concepts:**

- **RESTful Design:** The API follows REST principles, using predictable URLs and standard HTTP features.
- **HTTP Verbs:** Utilizes standard HTTP verbs (GET, POST, PUT, DELETE, etc.) for different actions.
- **JSON Payloads:** Expects request data in JSON format and returns responses in JSON. It's recommended to validate JSON structures using tools like [JSONLint](https://jsonlint.com/) during development.
  - **Caution:** Do not validate sensitive data like full card numbers or CVV/CVCs in external tools. Replace holder names with examples, but be mindful of special characters.
- **Compatibility:** Compatible with most standard HTTP clients (e.g., cURL, Python's `requests`, .NET's `HttpClient`).

## Authentication `[API_AUTH]`

Fat Zebra uses **HTTP Basic Authentication** over HTTPS. You will use your API username and token provided in the Merchant Dashboard as the username and password for Basic Auth.

- **Method:** HTTP Basic Authentication
- **Credentials:**
  - **Username:** Your API Username (e.g., `TEST`)
  - **Password:** Your API Token (e.g., `test_xxxxxxxxxxxxxxx`)
- **Example (cURL):** Replace `USERNAME` and `TOKEN` with your actual Sandbox or Production credentials.
  ```bash
  curl https://gateway.sandbox.fatzebra.com.au/v1.0/purchases \
       -u USERNAME:TOKEN \
       -d '{ "amount": 1000, "reference": "TestAuth1", "currency": "AUD", "card_holder": "Test", "card_number": "4111...1111", "card_expiry":"12/2029", "cvv": "123", "customer_ip": "127.0.0.1" }' \
       -H "Content-Type: application/json" \
       -X POST
  ```
- **Important:** All API requests must be made over HTTPS. Calls made over plain HTTP will fail. Keep your API token secure and do not expose it in client-side code.

## Endpoint Base URLs `[API_ENDPOINT]`

Fat Zebra provides separate base URLs for the Sandbox (testing) and Production (live) environments. The API version (e.g., `v1.0`) is part of the path.

- **Sandbox/Testing URL:** `https://gateway.sandbox.fatzebra.com.au/v1.0`
- **Production URL:** `https://gateway.fatzebra.com.au/v1.0`

_(Confirm these URLs and the latest version from the official 'Endpoint Base URLs' page if possible)_

## Errors & Timeouts `[API_ERROR]`

Fat Zebra uses standard HTTP status codes to indicate the success or failure of an API request.

- **Success:** `2xx` status codes indicate success (e.g., `200 OK`, `201 Created`).
- **Client Errors:** `4xx` status codes indicate an error with the client's request (e.g., missing required field, invalid data, authentication failure).
  - `400 Bad Request`: The request was malformed or missing parameters.
  - `401 Unauthorized`: Authentication failed (invalid username/token or incorrect scheme).
  - `403 Forbidden`: Authentication succeeded, but the user doesn't have permission for the action.
  - `404 Not Found`: The requested resource does not exist.
  - `422 Unprocessable Entity`: The request was well-formed but contained semantic errors (e.g., invalid card number format, business rule violation). Check the response body for details.
- **Server Errors:** `5xx` status codes indicate an error on Fat Zebra's servers. These should be rare. Retrying the request later may be appropriate.

  - `500 Internal Server Error`: Generic server error.
  - `503 Service Unavailable`: Temporary outage or maintenance.

- **Error Response Body:** When an error occurs (typically `4xx`), the response body will contain a JSON object with details:
  ```json
  {
    "errors": [
      {
        "message": "A human-readable error message.",
        "field": "Optional field name related to the error (e.g., 'card_number').",
        "code": "Optional machine-readable error code."
      }
      // Potentially more errors in the array
    ]
  }
  ```
- **Timeouts:** Network or processing timeouts can occur. Your HTTP client should be configured with reasonable timeout values (e.g., 30-60 seconds). If a timeout occurs, the status of the transaction is unknown. You may need to query the transaction status using its reference or ID later to confirm the outcome. Do not automatically assume failure on timeout for idempotent operations like creating a purchase.

---

_See also: [Purchases](./purchases.md), [API Response Codes](./purchases.md#response-codes)_
