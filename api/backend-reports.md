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
