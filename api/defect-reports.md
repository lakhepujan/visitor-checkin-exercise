## Defect 1: Deactivated user still appears in Active Visitor list
**Summary:** Deactivated user is still shown in the “Active Visitors” list.  
**Type:** Functional / Data Integrity  
**Description:** After a user is deactivated, they continue to appear in the Active Visitor list. This creates inconsistency between user status and what the application displays. This causes deactivated visitor records to remain visible in the active visitors list.


**Steps to Reproduce (Backend / Postman):**
1. Start the Rails API server.
2. Fetch existing visitors:
   - `GET /api/visitors`
3. Pick an existing visitor `id` from the response (example: `1`).
4. Deactivate that visitor:
   - `PATCH /api/visitors/1/deactivate`
5. Confirm the deactivate response indicates the visitor is deactivated:
   - `"active": false`
6. Fetch the visitors list again:
   - `GET /api/visitors`
7. Check whether visitor with ID `1` is still present and/or still treated as active in the response.


**Expected Result:** The deactivated user should not appear in the Active Visitors list and be excluded from “active” counts.  
**Actual Result:** The deactivated user still appears in the Active Visitors list as if they are active.

## Defect 2: Deactivated visitors returned in search results

**Summary:** Deactivated visitors are still returned in `GET /api/visitors/search`.  
**Type:** Functional  

### Description
The specification states that deactivated visitors must not be selectable for repeat visits. However, after deactivating a visitor, the deactivated visitor is still returned by the search endpoint `GET /api/visitors/search`. This allows deactivated visitors to remain searchable and therefore selectable for repeat visits, which violates the requirement.

### Steps to Reproduce
1. Ensure the Rails API server is running.
2. Deactivate an existing visitor (example: visitor with ID `1`) by sending:  
   - `PATCH /api/visitors/1/deactivate`
3. Confirm the response indicates the visitor is deactivated (e.g., `"active": false`).
4. Search for the visitor using the search endpoint, for example:  
   - `GET /api/visitors/search?full_name=Ana`
5. Check the response list for the deactivated visitor (ID `1`).

### Expected Result
Deactivated visitors (e.g., visitor with ID `1` with `"active": false`) should **NOT** be returned by `GET /api/visitors/search`, since deactivated visitors must not be selectable for repeat visits.

### Actual Result
The deactivated visitor (ID `1`) is still returned by `GET /api/visitors/search`.

## Defect 3: Re-checking out a visitor overwrites the original checked_out_at timestamp

**Summary:** Calling `checkout` API endpoint multiple times overwrites the existing `checked_out_at` value.  
**Type:** Functional / Data Integrity  

### Description
When a visitor is checked out for the first time, the API correctly stores the current timestamp in `checked_out_at`. However, if the same check-out endpoint is called again for the same visitor, the API updates `checked_out_at` again with a new timestamp. This overwrites the original check-out time and causes loss of historical accuracy.

This is a data integrity issue because `checked_out_at` should represent the moment the visitor actually checked out, and should not change once set.

### Steps to Reproduce 
1. Start the Rails API server.
2. Create a new visitor (or use an existing one that is currently not checked out):
   - `POST /api/visitors`
3. Note the returned visitor `id` (example: `81`).
4. Check out the visitor the first time:
   - `PATCH /api/visitors/81/check_out`
5. Confirm response contains a non-null `checked_out_at` timestamp.
6. Wait a few seconds.
7. Check out the same visitor again:
   - `PATCH /api/visitors/81/check_out`
8. Observe the `checked_out_at` timestamp again .

### Expected Result
If the visitor is already checked out (`checked_out_at` is not null), calling `PATCH /api/visitors/:id/check_out` again should **not** overwrite the original timestamp. The API should keep the initial `checked_out_at` value.

### Actual Result
On the second call, the API updates `checked_out_at` again, producing a new timestamp , overwriting the original value.

## Defect 4: API responses lack clear success/error messages 

**Summary:** API does not provide clear success and error messages, causing confusion during verification.  
**Type:** Usability / API Design  

### Description
Several API endpoints return only raw data objects on success and provide empty array for not found results. Because there is no explicit success message,error message, it becomes difficult for consumers (Postman testing or frontend UI) to confirm what happened (e.g., created successfully vs partially failed) and to display meaningful feedback to users.

This can lead to confusion during manual testing and also makes frontend development harder because the UI must guess how to interpret different responses.

### Steps to Reproduce
1. Start the Rails API server.
2. Trigger a successful action (example):
   - `POST /api/visitors` with a valid payload.
3. Observe the response body: it returns visitor data but no explicit success message.
4. Trigger a failing action (example):
   - `POST /api/visitors` with missing/invalid required fields (e.g., omit `full_name` if required).
5. Observe the error response body.

### Expected Result
- On success, API should return a consistent structure with confirmation, for example:
  - a `message` field like `"Visitor created successfully"`.
- On error, API should return:
  - appropriate HTTP status code (e.g., `422 Unprocessable Entity`),
  - validation details, and optionally
  - a clear message such as `"Validation failed"` / `"Visitor could not be created"`,”Visitor already checked out”.

### Actual Result
- Successful responses return only the raw serialized object with no message.

## Defect 5: Reuired full_name field accepts null values

**Summary:** `POST /api/visitors` allows creating a visitor even when required fields are missing or null.  
**Type:** Functional / Data Validation  

### Description
The API allows a visitor record to be created even if required visitor information is missing or provided as `null`/empty. This can lead to incomplete or invalid visitor records in the database and can break flows that depend on these fields (search, display, check-in/check-out).

### Steps to Reproduce
1. Start the Rails API server.
2. Send a create request with missing required fields (example: omit `full_name`), or set them as `null`:
   - `POST /api/visitors`
   - Body example:
     ```json
     {
       "full_name": null,
       "company_name": null,
        "purpose": "Backend internship assessment",
       "host_id": 1
     }
     ```
 3. Observe the response status and body.
4. Verify by fetching visitors:
   - `GET /api/visitors`
   - Confirm the created visitor appears with missing/null values.

### Expected Result
The API should reject invalid input and return an appropriate error response, for example:
- HTTP `422 Unprocessable Entity`
- A clear error payload indicating which fields are required, e.g.:
  ```json
  { "errors": { "full_name": ["can't be blank"] } }


## Defect 6: Newly added visitors appear at the end of the visitors list

**Summary:** New visitors created via `POST /api/visitors` appear at the end of `GET /api/visitors` results instead of appearing first.  
**Type:** Usability / Functional  

### Description
After creating a new visitor, fetching the visitors list (`GET /api/visitors`) returns records ordered such that the newly created visitor appears at the end of the list. This makes it harder for admins to confirm the newly added visitor and can require pagination/navigation to later pages to find the latest entry.

### Steps to Reproduce (Backend / Postman)
1. Start the Rails API server.
2. Fetch the current visitors list:
   - `GET /api/visitors?page=1`
   - Note down the IDs returned (especially the first and last IDs).
3. Create a new visitor:
   - `POST /api/visitors`
   - Send a valid request body (example):
     ```json
     {
       "full_name": "New Visitor",
       "company_name": "Test Company",
       “purpose: : “Added new visitor”
       "host_id": 1
     }
     ```
4. Copy the `id` of the newly created visitor from the response.
5. Fetch the visitors list again:
   - `GET /api/visitors?page=1`
6. Check where the newly created visitor appears in the response list.
7. If not found on page 1, request the next page(s) until the record appears:
   - `GET /api/visitors?page=2`

### Expected Result
Newly created visitors should appear at the top of the list by default (commonly ordered by most recent first, e.g., `created_at DESC` or `id DESC`), so the user can immediately see and verify the new entry without navigating to later pages.

### Actual Result
The newly created visitor appears at the end of the list response (or on later pages), requiring additional navigation/pagination to view the most recently added record.

## Defect 7: No loading, empty, or error state in the visitor list

**Summary:** `VisitorList.jsx` does not display loading indicators, empty state messages, or error messages during data fetch.  
**Type:** Usability  

### Description
The `VisitorList.jsx` component renders an empty `<tbody>` when the visitor list is empty or when the fetch request fails. There is no:
- **Loading indicator** while data is being fetched (important for slower network/API),
- **Empty state message** when there are no visitors to display,
- **Error message** when the API request fails.

As a result, users cannot distinguish between:
- "The list is still loading",
- "There are no visitors yet", or
- "Something went wrong (API error)".

This creates a poor user experience and makes debugging/testing harder.

### Steps to Reproduce
1 Run the frontend application without running the backend server.
2 The list area remains blank without any error identification.
3 Slow the API fetch process and observe the table for any loading message.

### Expected Result
The `VisitorList.jsx` component should display:
- A **loading indicator** while the fetch is in progress.
- An **empty state message** (e.g., "No visitors found") when the list is successfully fetched but empty.
- An **error message** (e.g., "Failed to load visitors. Please try again.") when the fetch request fails.

### Actual Result
The component renders an empty `<tbody>` in all three cases (loading, empty, error), providing no feedback to the user about the application state.
