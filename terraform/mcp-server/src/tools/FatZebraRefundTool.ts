import { MCPTool } from "mcp-framework";
import { z } from "zod";
import fetch from "node-fetch";

interface FatZebraRefundInput {
  transaction_id: string;
  amount: number;
  reference: string;
}

// Define request body interface
interface RefundRequestBody {
  transaction_id: string;
  amount: number;
  reference: string;
}

// Define response interface
interface FatZebraResponse {
  successful: boolean;
  errors?: string[];
  response: {
    id: string;
    amount: number;
    reference: string;
    transaction_id: string;
    message: string;
    currency: string;
    created_at: string;
  };
}

class FatZebraRefundTool extends MCPTool<FatZebraRefundInput> {
  name = "fat_zebra_refund";
  description = "Process a refund for a previous transaction using the Fat Zebra payment gateway";
  
  // Fat Zebra API configuration
  private baseUrl = process.env.FAT_ZEBRA_API_URL || "https://gateway.sandbox.fatzebra.com.au/v1.0";
  private username = process.env.FAT_ZEBRA_USERNAME || "TEST";
  private token = process.env.FAT_ZEBRA_TOKEN || "TEST";
  
  schema = {
    transaction_id: {
      type: z.string(),
      description: "The ID of the original transaction to refund",
    },
    amount: {
      type: z.number().positive(),
      description: "The amount to refund in cents (e.g., 1000 for $10.00)",
    },
    reference: {
      type: z.string(),
      description: "A unique reference for this refund transaction",
    }
  };

  async execute(input: FatZebraRefundInput) {
    try {
      // Generate a unique reference if none was provided
      const uniqueId = Date.now() + '-' + Math.random().toString(36).substring(2, 9);
      const reference = input.reference || `refund-${uniqueId}`;

      // Prepare the request body for the Fat Zebra API
      const requestBody: RefundRequestBody = {
        transaction_id: input.transaction_id,
        amount: input.amount,
        reference: reference,
      };

      // Make the request to the Fat Zebra API
      const response = await fetch(`${this.baseUrl}/refunds`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${Buffer.from(`${this.username}:${this.token}`).toString('base64')}`,
        },
        body: JSON.stringify(requestBody),
      });

      const data = await response.json() as FatZebraResponse;

      // Check if the response was successful
      if (!data.successful) {
        // Return the error response directly instead of throwing
        return {
          successful: false,
          errors: data.errors || ["Unknown error from Fat Zebra API"]
        };
      }

      // Return the response from Fat Zebra
      return {
        successful: data.successful,
        refund_id: data.response.id,
        amount: data.response.amount,
        reference: data.response.reference,
        transaction_id: data.response.transaction_id,
        message: data.response.message,
        currency: data.response.currency,
        timestamp: data.response.created_at,
      };
    } catch (error) {
      console.error('Error processing refund:', error);
      // Return error as a response instead of throwing
      return {
        successful: false,
        errors: [(error instanceof Error ? error.message : String(error))]
      };
    }
  }
}

export default FatZebraRefundTool; 