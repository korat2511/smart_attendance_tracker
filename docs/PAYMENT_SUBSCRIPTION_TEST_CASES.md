# Payment and Subscription Test Cases

All scenarios with concrete examples. What happens in the app, in your database, and in Razorpay.

Signup in this app is done with name, email, mobile, business name, staff size and password. There is no OTP in the signup or login flow.

After trial ends Razorpay auto-debits 99 INR on the next billing date. The user does not manually pay. If the card is saved and valid the charge happens automatically.

---

## Example 1. User signs up and starts trial

**User 1 Rahul**

- Date: 1 Mar 2026
- Action: Rahul opens app. Taps Sign up. Enters name Rahul, email rahul@test.com, mobile 9876543210, business name My Shop, staff size 5, password. Taps Sign up.
- Result: App shows subscription screen with trial offer (2 INR for 1 day then 99 per month).

**Database after signup**

- Table users: 1 row. id 1, name Rahul, email rahul@test.com, mobile 9876543210, business_name My Shop, staff_size 5, password hashed.
- Table subscriptions: empty.
- Table subscription_trials: empty.

**Razorpay:** Nothing yet.

---

- Date: 1 Mar 2026 (same day)
- Action: Rahul taps Subscribe. Pays 2 INR (trial) via Razorpay. Payment succeeds.
- Result: App shows Home. Rahul has access for 1 day trial.

**Database after trial payment**

- Table users: unchanged (still 1 row).
- Table subscriptions: 1 row. user_id 1, razorpay_subscription_id sub_xxx, razorpay_plan_id plan_xxx, razorpay_customer_id cus_xxx, status authenticated or created, trial_ends_at 2 Mar 2026 (1 day from now), current_period_start null, current_period_end null, amount 99, cancel_at_period_end 0.
- Table subscription_trials: 1 row. user_id 1, mobile 9876543210, trial_used_at 1 Mar 2026.

**Razorpay**

- Customers: 1 customer for Rahul (created by app when creating subscription).
- Subscriptions: 1 subscription. Plan 99 INR monthly. Addon 2 INR (trial). Start at = 2 Mar (billing starts after trial). Status authenticated or created.
- Payments: 1 payment of 2 INR for the trial addon.

---

## Example 2. Trial ends and first monthly charge (auto-debit)

**User 1 Rahul**

- Date: 2 Mar 2026 (trial_ends_at reached)
- Action: Rahul does nothing. Razorpay automatically charges 99 INR on the billing date (after trial end).
- Result: Payment succeeds. Subscription becomes paid. Rahul keeps access until next period end.

**Database after first 99 charge**

- Table subscriptions: same row updated. status active. trial_ends_at still 2 Mar (past). current_period_start 2 Mar 2026, current_period_end 2 Apr 2026 (or similar). Webhook or sync updates this.
- Table subscription_trials: unchanged.

**Razorpay**

- Subscriptions: Same subscription. Status active. Current period 2 Mar to 2 Apr.
- Payments: New payment 99 INR for first cycle.

User does not manually pay. Razorpay auto-debits 99 on the cycle date.

---

## Example 3. User signs up with same mobile that already used trial

**User 2 Priya**

- Date: 5 Mar 2026
- Action: Priya signs up with mobile 9876543210 (same as Rahul). Name Priya, email priya@test.com, business name Other Shop, password etc.
- Result: User created. Subscription screen shows only 99 per month. No trial offer because mobile 9876543210 is already in subscription_trials.

**Database after signup**

- Table users: 2 rows. Second row id 2, mobile 9876543210, name Priya etc.
- Table subscription_trials: still 1 row (mobile 9876543210). Trial is per mobile so Priya cannot get trial.
- Table subscriptions: still only Rahul subscription.

**Razorpay:** No new subscription until Priya taps Subscribe and pays 99.

---

## Example 4. User cancels trial from app

**User 1 Rahul**

- Date: 1 Mar 2026 (still in trial)
- Action: Rahul has started trial. He opens Settings. Taps Cancel subscription.
- Result: App calls cancel API. Trial is cancelled immediately in Razorpay. No 99 charge will happen.

**Database after cancel trial**

- Table subscriptions: same row. cancel_at_period_end 1. metadata has cancelled_at timestamp.
- Razorpay subscription is cancelled (cancel_at_cycle_end 0 so immediate).

**Razorpay**

- Subscriptions: That subscription status becomes cancelled. No future charge.

---

## Example 5. User cancels paid subscription from app

**User 1 Rahul**

- Date: 15 Mar 2026 (paid period 2 Mar to 2 Apr)
- Action: Rahul opens Settings. Taps Cancel subscription.
- Result: App sets cancel_at_period_end true. Razorpay is told cancel at cycle end. Rahul keeps access until 2 Apr. On 2 Apr no more charge.

**Database after cancel paid**

- Table subscriptions: cancel_at_period_end 1. status still active until period end.
- Razorpay: Subscription has scheduled cancel at cycle end. After 2 Apr status becomes cancelled.

---

## Example 6. User cancels from Razorpay dashboard

**User 1 Rahul**

- Date: 10 Mar 2026
- Action: You open Razorpay test dashboard. Find Rahul subscription. Cancel it (at cycle end or immediately).
- Result: Razorpay status changes. App database still has old state until sync.

**When Rahul opens app**

- App may call getStatus or sync. Backend fetches subscription from Razorpay. Sees cancelled or scheduled cancel. Updates DB. has_active_plan and has_free_trial become false when period ended or cancelled. Rahul is sent to subscription screen.

**Database after sync**

- Table subscriptions: status cancelled (or cancel_at_period_end true if at cycle end). current_period_end updated from Razorpay if needed.

---

## Example 7. Resubscribe after subscription ended

**User 1 Rahul**

- Date: 5 Apr 2026 (subscription was cancelled and period ended 2 Apr)
- Action: Rahul opens app. Sees subscription screen. Taps Subscribe. Pays 99 INR.
- Result: create API checks latest subscription. Status is cancelled or completed so allowed. New Razorpay subscription created. New row in subscriptions table.

**Database after resubscribe**

- Table subscriptions: 2 rows for user_id 1. First row status cancelled. Second row new subscription id, status authenticated or active, current_period_start 5 Apr, current_period_end 5 May.
- Table subscription_trials: unchanged (mobile already used trial).

**Razorpay**

- Subscriptions: New subscription for same customer. New sub_yyy id. 99 INR monthly.

---

## Example 8. First payment fails (trial 2 INR)

**User 3 Amit**

- Date: 6 Mar 2026
- Action: Amit signs up. Taps Subscribe. Uses test card that declines. Payment fails.
- Result: Razorpay returns failure. App shows error. No subscription is created.

**Database**

- Table users: 1 row for Amit.
- Table subscriptions: no row for Amit.
- Table subscription_trials: no row (trial not used because payment failed).

**Razorpay:** Maybe a failed payment record. No active subscription. Amit can retry Subscribe with valid card.

---

## Example 9. Renewal payment fails (auto-debit fails)

**User 1 Rahul**

- Date: 2 Apr 2026 (next billing date)
- Action: Rahul had paid period 2 Mar to 2 Apr. Razorpay tries to auto-charge 99. Card declined or insufficient funds.
- Result: Razorpay charge fails. Razorpay may set subscription to halted or keep pending. Webhook or sync updates app DB.

**Database after failure**

- Table subscriptions: status may become halted or stay active with failed payment. Depends on Razorpay webhook.
- User may lose access or see limited state until payment is retried or method updated in Razorpay.

---

## Example 10. Already have active subscription and tap Subscribe again

**User 1 Rahul**

- Date: 20 Mar 2026 (he has active paid plan until 2 Apr)
- Action: Rahul taps Subscribe again (e.g. from subscription screen if he navigated there).
- Result: create API finds latest subscription not cancelled. Returns 400. Message: You already have an active subscription. App may show error or refresh status and redirect to Home.

**Database and Razorpay:** No change. Still one active subscription.

---

## Summary table

| Scenario | Who | Action | Database | Razorpay |
|----------|-----|--------|----------|----------|
| Signup first time | Rahul | Sign up with mobile and password | users +1 row | Nothing |
| Start trial | Rahul | Pay 2 INR trial | subscriptions +1, subscription_trials +1 | Customer +1, Subscription +1, Payment 2 INR |
| Trial ends | Rahul | Nothing (auto) | subscription updated by webhook | Auto charge 99 INR. Subscription active |
| Signup same mobile as trial | Priya | Sign up 9876543210 | users +1. No new trial row | Nothing until she pays 99 |
| Cancel trial from app | Rahul | Cancel in Settings | cancel_at_period_end 1 | Subscription cancelled |
| Cancel paid from app | Rahul | Cancel in Settings | cancel_at_period_end 1 | Scheduled cancel at cycle end |
| Cancel from dashboard | You | Cancel in Razorpay | Updated when app syncs | Status cancelled |
| Resubscribe after end | Rahul | Subscribe and pay 99 | subscriptions +1 new row | New subscription |
| First payment fails | Amit | Pay trial but card declines | No subscription row | No subscription. Can retry |
| Renewal fails | Rahul | Auto charge on 2 Apr fails | status may halted | Subscription halted or retry |

---

## Quick reference

- Signup: name, email, mobile, business name, staff size, password. No OTP.
- Trial: 1 day. 2 INR one-time. One per mobile. After trial Razorpay auto-debits 99 each month.
- Cancel from app: Trial cancelled immediately in Razorpay. Paid cancelled at cycle end so access until current_period_end.
- Cancel from Razorpay: App gets new state when user opens app and sync or getStatus runs.
- Resubscribe: Allowed when subscription status is cancelled or completed or expired. Same mobile cannot get trial again.
