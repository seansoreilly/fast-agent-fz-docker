import { MCPTool } from "mcp-framework";
import { z } from "zod";
import fetch from "node-fetch";

interface FatZebraDirectDebitInput {
  amount: number;
  description: string;
  reference: string;
  account_name: string;
  bsb: string;
  account_number: string;
  customer_name?: string;
  customer_email?: string;
  customer_ip?: string;
  metadata?: Record<string, string>;
}

// Define request body interface
interface DirectDebitRequestBody {
  amount: number;
  description: string;
  reference: string;
  account_name: string;
  bsb: string;
  account_number: string;
  customer_ip?: string;
  customer_name?: string;
  customer_email?: string;
  metadata?: Record<string, string>;
}

// Define response interface
interface FatZebraDirectDebitResponse {
  successful: boolean;
  errors?: string[];
  response?: {
    id: string;
    amount: number;
    decimal_amount: number;
    successful: boolean;
    message: string;
    reference: string;
    settlement_date: string;
    transaction_date: string;
    status: string;
    metadata: Record<string, string>;
    addendum_data: Record<string, any>;
    account_name: string;
    account_number: string;
    account_routing: string;
  };
  test: boolean;
}

class FatZebraDirectDebitTool extends MCPTool<FatZebraDirectDebitInput> {
  name = "fat_zebra_direct_debit";
  description = "Create a direct debit payment using the Fat Zebra payment gateway";
  
  // Fat Zebra API configuration
  private baseUrl = process.env.FAT_ZEBRA_API_URL || "https://gateway.sandbox.fatzebra.com.au/v1.0";
  private username = process.env.FAT_ZEBRA_USERNAME || "TEST";
  private token = process.env.FAT_ZEBRA_TOKEN || "TEST";
  
  // Default test bank account details
  private defaultAccountName = "Test Account";
  private defaultBSB = "000-000"; // Test BSB
  private defaultAccountNumber = "12345678"; // Test account number
  
  schema = {
    amount: {
      type: z.number().positive(),
      description: "The amount to debit in cents (e.g., 1000 for $10.00)",
    },
    description: {
      type: z.string().max(18),
      description: "A description of the direct debit transaction (maximum 18 characters)",
    },
    reference: {
      type: z.string(),
      description: "A unique reference for this transaction",
    },
    account_name: {
      type: z.string(),
      description: "The name of the account to debit",
    },
    bsb: {
      type: z.string(),
      description: "The BSB number of the account (format: XXX-XXX)",
    },
    account_number: {
      type: z.string(),
      description: "The account number to debit",
    },
    customer_name: {
      type: z.string().optional(),
      description: "The customer's name (optional)",
    },
    customer_email: {
      type: z.string().email().optional(),
      description: "The customer's email address (optional)",
    },
    customer_ip: {
      type: z.string().optional(),
      description: "The customer's IP address (optional)",
    },
    metadata: {
      type: z.record(z.string()).optional(),
      description: "Additional metadata to store with the transaction (optional)",
    }
  };

  async execute(input: FatZebraDirectDebitInput) {
    try {
      // Use test account details if we're in test mode and no details are provided
      const accountName = this.username === "TEST" && !input.account_name ? 
        this.defaultAccountName : input.account_name;
      
      // Format BSB correctly if needed (ensure XXX-XXX format)
      let bsb = input.bsb || this.defaultBSB;
      // If BSB doesn't contain a hyphen, format it as XXX-XXX
      if (bsb && !bsb.includes('-')) {
        bsb = bsb.length === 6 ? `${bsb.substring(0, 3)}-${bsb.substring(3)}` : bsb;
      }
      
      const accountNumber = this.username === "TEST" && !input.account_number ? 
        this.defaultAccountNumber : input.account_number;
      
      // Create a unique reference with timestamp AND random string to ensure uniqueness
      const uniqueId = Date.now() + '-' + Math.random().toString(36).substring(2, 9);
      const reference = input.reference || `dd-${uniqueId}`;
      
      // Truncate description to 18 characters if it's longer
      const description = input.description.length > 18 ? 
        input.description.substring(0, 18) : 
        input.description;
      
      // Prepare the request body for the Fat Zebra API
      const requestBody: DirectDebitRequestBody = {
        amount: input.amount,
        description: description,
        reference: reference,
        account_name: accountName,
        bsb: bsb,
        account_number: accountNumber
      };

      // Add optional fields only if provided
      if (input.customer_ip) {
        requestBody.customer_ip = input.customer_ip;
      }
      
      if (input.customer_name) {
        requestBody.customer_name = input.customer_name;
      }
      
      if (input.customer_email) {
        requestBody.customer_email = input.customer_email;
      }
      
      if (input.metadata) {
        requestBody.metadata = input.metadata;
      }

      // Make the request to the Fat Zebra API
      const response = await fetch(`${this.baseUrl}/direct_debits`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${Buffer.from(`${this.username}:${this.token}`).toString('base64')}`,
        },
        body: JSON.stringify(requestBody),
      });

      const data = await response.json() as FatZebraDirectDebitResponse;

      // Check if the response was successful
      if (!data.successful) {
        // Return the error response directly instead of throwing
        return {
          successful: false,
          errors: data.errors || ["Unknown error from Fat Zebra API"]
        };
      }

      // Return the direct debit information
      return {
        successful: data.successful,
        transaction_id: data.response?.id || "",
        amount: data.response?.amount || 0,
        reference: data.response?.reference || "",
        message: data.response?.message || "",
        status: data.response?.status || "",
        settlement_date: data.response?.settlement_date || "",
        transaction_date: data.response?.transaction_date || "",
        account_name: data.response?.account_name || "",
        // Mask the account number for security
        account_number: data.response?.account_number?.replace(/\d(?=\d{4})/g, "*") || "",
        account_routing: data.response?.account_routing || "",
        test: data.test
      };
    } catch (error) {
      console.error('Error processing direct debit:', error);
      // Return error as a response instead of throwing
      return {
        successful: false,
        errors: [(error instanceof Error ? error.message : String(error))]
      };
    }
  }
}

export default FatZebraDirectDebitTool; 