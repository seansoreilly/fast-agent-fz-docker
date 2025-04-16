# Fat Zebra SDKs

Fat Zebra provides Software Development Kits (SDKs) to simplify integration, especially for client-side implementations (web and mobile), helping to reduce PCI scope.

## React SDK `[SDK:REACT]`

_(Verify details against official 'React SDK' documentation)_

- **Overview:** Provides React components to embed secure payment forms within your React application. Handles rendering input fields (potentially using hosted fields/iframes for PCI compliance), client-side validation, tokenization, and potentially 3DS challenge flows.
- **Installation:** Likely available via npm/yarn. Example:
  ```bash
  npm install @fatzebra/react-sdk # Confirm package name
  # or
  yarn add @fatzebra/react-sdk
  ```
- **Usage:** Typically involves importing components (e.g., `FatZebraProvider`, `CardForm`, `SubmitButton`) and wrapping your checkout form.

  ```jsx
  // Example Usage (Illustrative - Confirm component names and props)
  import React, { useState } from "react";
  import { FatZebraProvider, CardForm, useFatZebra } from "@fatzebra/react-sdk";

  const CheckoutForm = () => {
    const { tokenize } = useFatZebra();
    const [error, setError] = useState(null);

    const handleSubmit = async (event) => {
      event.preventDefault();
      setError(null);
      try {
        const tokenPayload = await tokenize(); // Gets token from hosted fields
        console.log("Token:", tokenPayload.token);
        // Send tokenPayload.token to your server for processing
        // await fetch('/your-server/process-payment', { method: 'POST', body: JSON.stringify({ token: tokenPayload.token }) });
      } catch (err) {
        console.error("Tokenization Error:", err);
        setError(err.message || "Payment failed");
      }
    };

    return (
      <form onSubmit={handleSubmit}>
        <CardForm /> {/* Renders hosted fields for number, expiry, CVV */}
        {error && <div style={{ color: "red" }}>{error}</div>}
        <button type="submit">Pay Now</button>
      </form>
    );
  };

  const App = () => (
    <FatZebraProvider
      apiKey="YOUR_PUBLISHABLE_API_KEY" /* or other auth method */
    >
      <CheckoutForm />
    </FatZebraProvider>
  );
  ```

- **Key Components/Props:** Look for components like `FatZebraProvider` (for setup/auth), `CardNumberElement`, `CardExpiryElement`, `CardCvvElement` (individual hosted fields), `CardForm` (composite component), hooks like `useFatZebra` for accessing methods (`tokenize`, `handle3DS`), and props for styling/customization.

## Javascript SDK `[SDK:JS]`

_(Verify details against official 'Javascript SDK' documentation)_

Provides functionality for standard Javascript web integrations (and potentially Node.js), focusing on client-side tokenization and handling payments/3DS to minimize PCI scope.

### Features

- Securely rendering card input fields (likely using hosted fields/iframes).
- Client-side card detail validation.
- Tokenization of card details.
- Initiating purchases (potentially directly or returning a token for server-side processing).
- Handling 3D Secure challenges.
- Integration with Fat Zebra's Hosted Payment Page (HPP).

### Setup / Authentication

- **Obtaining OAuth Token:** Some client-side operations might require a short-lived OAuth token obtained from your server to authenticate the SDK session securely.
- **Initialization:** Include the SDK script and initialize it, typically with a publishable API key or the obtained OAuth token.

  ```javascript
  // Example Initialization (Illustrative - confirm auth method)
  <script src="https://js.fatzebra.com.au/v2/fatzebra.js"></script> // Confirm URL
  <script>
    const fz = new FatZebra({
      publishableKey: 'pk_test_yourkey' // Or other auth like oauthToken
    });

    // --- Mount hosted fields ---
    const cardNumber = fz.createHostedField('cardNumber');
    cardNumber.mount('#card-number-element');
    // ... mount expiry, cvv ...
  </script>
  ```

### Key Methods

- **`constructor(options)`:** Initializes the SDK with configuration (auth keys, etc.).
- **`createHostedField(type)`:** Creates an iframe-based input field for secure data entry (`cardNumber`, `cardExpiry`, `cardCvv`). Returns an element object with `mount()`, `unmount()`, `on()` methods.
- **`tokenize(options)`:** Collects data from mounted hosted fields and attempts to create a card token. Returns a Promise resolving with the token payload or rejecting with an error.
- **`purchase(params)`:** May initiate a purchase directly from the client-side (requires careful consideration of security/fraud implications) or handle 3DS flow after server initiates.
- **`verifyCard(params)`:** Similar to `tokenize`, but specifically for creating a token without necessarily making a purchase.
- **`renderPaymentsPage(params)`:** Redirects to or renders the Fat Zebra Hosted Payment Page based on provided setup parameters.
- **`handle3DS(params)`:** Method to handle the 3DS challenge flow based on data returned from a server-side API call that indicated 3DS was required.

### Data Objects

- **`Customer`:** Object for customer details (name, email, address).
- **`PaymentIntent`:** Often used server-side to represent the intent to collect payment, may generate a `client_secret` used by the JS SDK.
- **`PaymentMethod`:** Represents a payment method, often the result of tokenization, containing the `token` ID.
- **`HppSetupParams`:** Configuration for `renderPaymentsPage` (amount, currency, reference, return_url, etc.).
- **`VerifyCardParams` / `TokenizeParams`:** Options for tokenization methods (e.g., customer details, address for AVS).

### Events & Listeners

Hosted field elements emit events (`change`, `focus`, `blur`, `ready`, `validationError`) that can be listened to using the `.on()` method. The main `fz` instance might also emit events related to tokenization or payment states.

- **`change` (on Field):** Fired when the field value changes. Payload includes `elementType`, `empty`, `complete`, `error`.
- **`tokenization.success` / `payment.success` (on Instance):** Fired on successful completion.
- **`tokenization.error` / `payment.error` (on Instance):** Fired on failure.
- **`sca.required` (on Instance):** Fired if a 3DS challenge is needed.

**Example Listener (Hosted Field):**

```javascript
cardNumber.on("change", (event) => {
  const displayError = document.getElementById("card-errors");
  if (event.error) {
    displayError.textContent = event.error.message;
  } else {
    displayError.textContent = "";
  }
});
```

---

_See also: [Getting Started](./getting-started.md), [Purchases](./purchases.md), [Card On File](./card-on-file.md), [Security](./security.md), [3DS2 Integration](./3ds2.md)_
