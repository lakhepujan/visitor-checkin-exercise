# Backend-notes.md - Pujan Lakhe

## Defect selected and why

### D1: Deactivated user still appears in Active Visitor list** 

I selected  this because:

- It is a **data integrity + functional correctness** issue: the “active visitors” endpoint should not return deactivated visitors.
- It can cause real product impact: wrong active counts, incorrect UI display, and confusion for staff/admins.
- The fix is small and safe (query filter), and can be verified clearly with a request spec.

## Fix summary
Updated `GET /api/visitors` to exclude inactive visitors:
```ruby
visitors = Visitor.where(checked_out_at: nil, active: true)
```

## Why I selected Defect 2

I selected **Defect 2: Deactivated visitors returned in search results** because:

- It is a **functional correctness and security issue**: the search endpoint is used to find visitors for repeat check-ins, and deactivated visitors must not be selectable for this purpose.
- It can cause real product impact: unauthorized or terminated individuals could be re-admitted, violating security policies and causing confusion for staff.
- The fix is small and safe (query filter), and can be verified clearly with a request spec.

## Fix summary

Updated `GET /api/visitors/search` to exclude inactive visitors:

```ruby
visitors = Visitor.where("full_name ILIKE ?", "%#{query}%").where(active: true)
```
