# API Pagination `[API_PAGINATION]`

This section describes how pagination is handled for API endpoints that return lists of resources (e.g., lists of transactions, customers).

## Requesting Pages

To control pagination, use the following standard query parameters:

- **`page`:** (Integer, Optional, Default: 1) Specifies the page number to retrieve. The first page is `1`.
- **`per_page`:** (Integer, Optional, Default: 25, Max: 100) Specifies the maximum number of items to return per page.

**Example Request:**

Retrieve the third page of purchases, with 20 items per page:

```http
GET /v1.0/purchases?page=3&per_page=20
Host: gateway.fatzebra.com.au
Authorization: Basic YOUR_USERNAME:YOUR_TOKEN
Accept: application/json
```

## Reading Pagination Info from Responses

Responses for endpoints that support pagination include a `pagination` object within the JSON body. This object contains metadata about the result set.

- **`total_entries`:** (Integer) The total number of resources available across all pages for the given query.
- **`total_pages`:** (Integer) The total number of pages available.
- **`current_page`:** (Integer) The page number that was returned in this response.
- **`per_page`:** (Integer) The number of items requested per page.

**Example Response Snippet:**

```json
{
  "purchases": [
    // ... 20 purchase objects ...
  ],
  "pagination": {
    "total_entries": 123,
    "total_pages": 7,
    "current_page": 3,
    "per_page": 20
  }
}
```

**Note:** Check the `total_pages` value to determine if more pages are available. Iterate by incrementing the `page` parameter in subsequent requests until `current_page` equals `total_pages`.

---

_See also: [Getting Started](./getting-started.md)_
