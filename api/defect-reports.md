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
