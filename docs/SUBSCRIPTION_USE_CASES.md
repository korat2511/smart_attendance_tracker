# Subscription Use Cases – End-to-End Flows

This document describes all possible subscription flows: signup, free trial, paid subscription, cancellation (on trial and on paid), and how the backend, Razorpay, and the mobile app behave in each case.

---

## 1. User signup

| Step | What happens |
|------|-----------------------------|
| **App** | User signs up (name, mobile, email, password). On success, app saves token + user and navigates to **SubscriptionScreen** (not Home). |
| **Backend** | Auth API creates user; no subscription record yet. |
| **Razorpay** | Nothing. |
| **App screen** | **Upgrade to Pro** – if first-time (no trial used for this mobile): shows **7-day trial ₹2** then ₹99/month; else shows **₹99/month** only and “Free trial already used for this number”. |

**Summary:** After signup, user always lands on Subscription screen to start trial or subscribe. No subscription or Razorpay record until they tap Start Trial / Subscribe.

---

## 2. Take free trial (first time, eligible)

| Step | What happens |
|------|-----------------------------|
| **App** | User taps “Start Trial” on SubscriptionScreen. App calls `createSubscription()`, gets `subscription_id` + Razorpay key, opens Razorpay checkout (₹2 trial charge). On payment success callback, app calls `checkSubscriptionStatus()` then navigates to Home. |
| **Backend** | **POST subscription/create:** Checks `canUserUseTrial(user_id, mobile)` (no row in `subscription_trials`, no prior subscription with `trial_ends_at`). Creates Razorpay subscription with `start_at` = now + 7 days and trial addon (₹2). Creates **Subscription** row: `status` from Razorpay (e.g. `created`/`authenticated`), `trial_ends_at` = now + 7 days. Inserts **subscription_trials** (mobile, user_id, trial_used_at) so this number cannot get trial again. |
| **Razorpay** | Creates subscription in trial; may send `subscription.authenticated` (and later `subscription.activated` when first charge is authorised). |
| **App screen** | After payment: Home. Settings → Subscription: **Free Trial** card, “Subscription will start from &lt;date&gt;”, “Cancel before renewal” button. |

**Summary:** One subscription row (trial), one `subscription_trials` row. User has access until `trial_ends_at`. Razorpay will charge ₹99 at trial end unless cancelled.

---

## 3. Start subscription (paid) – two sub-cases

### 3a. User never had trial (e.g. signed up but went back; or new device same number)

| Step | What happens |
|------|-----------------------------|
| **App** | SubscriptionScreen shows **₹99/month** only (and “Free trial already used” if number already used trial elsewhere). User taps “Subscribe Now”, pays via Razorpay. |
| **Backend** | **POST subscription/create:** `canUserUseTrial` = false (either in `subscription_trials` or has existing subscription with `trial_ends_at`). Creates Razorpay subscription **without** trial (no `start_at` addon). Creates **Subscription** row: no `trial_ends_at`, `status` from Razorpay. |
| **Razorpay** | Subscription starts; first charge (₹99) and recurring charges. Webhooks: `subscription.charged`, `subscription.activated`, etc. |
| **App screen** | After payment: Home. Settings → **Premium Active**, “Renews at &lt;date&gt;”, “Cancel subscription” button. |

### 3b. Trial ends and first ₹99 charge succeeds (continuation of §2)

| Step | What happens |
|------|-----------------------------|
| **Razorpay** | At `trial_ends_at`, Razorpay charges ₹99. Sends **subscription.charged** (and possibly **subscription.activated**). |
| **Backend** | **Webhook subscription.charged:** Finds subscription by `razorpay_subscription_id`, sets `status` = `active`, `current_period_end` (and `charge_at`) from payload. **subscription.activated:** Same + ensures `subscription_trials` has this mobile (trial used). |
| **App** | On next open or when user opens Settings, `getStatus` returns `has_active_plan` = true, `has_free_trial` = false (because `trial_ends_at` is now in the past). |
| **App screen** | Settings → **Premium Active**, “Renews at &lt;current_period_end&gt;”, “Cancel subscription”. |

**Summary:** After trial end, one successful charge moves the user to “Premium Active” in app and backend; Razorpay continues recurring billing.

---

## 4. Cancel on trial (before trial end)

| Step | What happens |
|------|-----------------------------|
| **App** | User goes to Settings → Subscription, taps “Cancel before renewal”, confirms. App calls `cancelSubscription()` (POST subscription/cancel), then `checkSubscriptionStatus()`. |
| **Backend** | **POST subscription/cancel:** Finds subscription by user_id with `status` in `['active','authenticated','pending','created']`. **Immediately** updates our DB: `cancel_at_period_end` = true, `metadata.cancelled_at` = now. Then calls Razorpay **POST /subscriptions/{id}/cancel** with `cancel_at_cycle_end` = 1. Razorpay may fail for trial/created subscriptions; we still return 200. |
| **Razorpay** | May accept or reject cancel-at-cycle-end (e.g. for “created” trial). No immediate status change required for our logic; we rely on our DB flag. |
| **App screen** | Success snackbar. Settings → **Trial until &lt;date&gt;** card, “You cancelled — you won't be charged when the trial ends.”, **Activate again** button (no more “Cancel before renewal”). |

**Razorpay:** For **trial** subscriptions we call cancel with `cancel_at_cycle_end` = **false** (cancel immediately) so Razorpay marks the subscription cancelled and **does not** show “Next Due” or attempt any charge. For paid subscriptions we use `cancel_at_cycle_end` = true.

**Summary:** Our backend sets `cancel_at_period_end` = true and tells Razorpay to cancel: **immediately** for trial (no charge), **at cycle end** for paid. UI shows “cancelled trial” and “Activate again”.

---

## 5. Cancel on subscription (paid, during active period)

| Step | What happens |
|------|-----------------------------|
| **App** | User goes to Settings → Subscription, taps “Cancel subscription”, confirms. App calls `cancelSubscription()` then `checkSubscriptionStatus()`. |
| **Backend** | **POST subscription/cancel:** Same as §4: find subscription, set `cancel_at_period_end` = true in DB, then call Razorpay cancel with `cancel_at_cycle_end` = 1. Returns 200. |
| **Razorpay** | Marks subscription to cancel at end of current billing cycle. At period end: stops renewal, may send **subscription.cancelled** webhook. |
| **App screen** | Success snackbar. Settings → **Active until &lt;current_period_end&gt;** card, “You have access until the end of your billing period.”, “You cancelled. Your plan will not renew.”, **Activate again** button. |

**Summary:** User keeps access until `current_period_end`; no further charges after that. App shows “cancelled paid” state with “Activate again”.

---

## 6. Cancel after 2–3 autopay (paid user, has been charged 2–3 times)

Same as **§5** in behaviour; only the “age” of the subscription differs.

| Step | What happens |
|------|-----------------------------|
| **Backend** | Subscription has `status` = `active`, `current_period_end` = end of current cycle (e.g. after 2nd or 3rd charge). **POST subscription/cancel:** Sets `cancel_at_period_end` = true. Razorpay API called with `cancel_at_cycle_end` = 1. |
| **Razorpay** | Subscription remains `active` until `current_end`. No more charges after that; subscription moves to `cancelled`. Razorpay sends **subscription.cancelled** at period end. |
| **Backend (webhook)** | **subscription.cancelled:** `RazorpayWebhookController` finds subscription by `razorpay_subscription_id`, updates: `status` = `cancelled`, `cancel_at_period_end` = false (cleanup). |
| **App** | Until period end: same as §5 – “Active until &lt;date&gt;”, “You cancelled”, “Activate again”. After period end: next `getStatus` returns `has_active_plan` = false (status `cancelled` and/or `current_period_end` in the past), so user sees **No Active Plan** and “Activate again”. |

**Summary:** Backend and Razorpay stay in sync: we set cancel intent in our DB and tell Razorpay; at period end Razorpay cancels and we sync via webhook. App shows “active until date” then “No Active Plan” after that date.

---

## 7. Autopay cancelled / paused by bank or UPI (Razorpay status = halted)

| Step | What happens |
|------|-----------------------------|
| **Razorpay** | Stops charging (e.g. user revoked mandate). Sends **subscription.halted**. |
| **Backend** | **Webhook subscription.halted:** Updates subscription `status` = `halted`. No change to `cancel_at_period_end`. |
| **App** | `getStatus` returns `subscription_status` = `halted`. App uses `isAutopayCancelled` (status == `halted`). |
| **App screen** | Settings → **Active until &lt;date&gt;** card, “Autopay cancelled or paused. Activate again to use features after this period.”, **Activate again** button. |

**Summary:** User did not cancel in app; payment method failed or was removed. App shows “Autopay cancelled” and “Activate again” (resubscribe).

---

## 8. App launch (splash) – who goes where

| User state | Backend `getStatus` | App after splash |
|------------|---------------------|------------------|
| Not logged in | — | **LoginScreen** |
| Logged in, no subscription | `has_active_plan`=false, `has_free_trial`=false | **SubscriptionScreen** |
| Logged in, trial active | `has_free_trial`=true | **HomeScreen** |
| Logged in, trial cancelled | `has_free_trial`=true, `cancel_at_period_end`=true | **HomeScreen** (access until trial end) |
| Logged in, paid active | `has_active_plan`=true | **HomeScreen** |
| Logged in, paid cancelled (before period end) | `has_active_plan`=true, `cancel_at_period_end`=true | **HomeScreen** (access until period end) |
| Logged in, period/trial ended or cancelled | `has_active_plan`=false, `has_free_trial`=false | **SubscriptionScreen** |
| Logged in, subscription check API error | — | **SubscriptionScreen** (no access without verification) |

---

## 9. Backend status fields (GET subscription/status)

| Field | Meaning |
|-------|--------|
| `has_active_plan` | Paid plan active and `current_period_end` ≥ today (not in trial period). |
| `has_free_trial` | `trial_ends_at` is in the future. |
| `trial_ends_at` | End of 7-day trial (if any). |
| `current_period_end` | End of current billing period (from Razorpay/webhooks). |
| `cancel_at_period_end` | User (or flow) requested cancel; plan will not renew after period/trial end. |
| `subscription_status` | Razorpay status: `created`, `authenticated`, `active`, `pending`, `halted`, `cancelled`, `completed`. |
| `can_use_trial` | One-time trial not used for this mobile and no prior subscription with trial. |

---

## 10. Razorpay webhooks we use

| Event | Backend action |
|-------|----------------|
| subscription.authenticated | Update subscription `status` = `authenticated`. |
| subscription.activated | Update `status` = `active`; ensure `subscription_trials` has this mobile. |
| subscription.charged | Update `status` = `active`, `current_period_end`, `charge_at`. |
| subscription.pending | Update `status` = `pending`. |
| subscription.halted | Update `status` = `halted`. |
| subscription.cancelled | Update `status` = `cancelled`, `cancel_at_period_end` = false. |
| subscription.completed | Update `status` = `completed`. |

---

## 11. Quick reference – “What do I see in the app?”

| Scenario | Settings subscription card | Main action |
|----------|----------------------------|-------------|
| Free trial, not cancelled | Free Trial, “Cancel before renewal” | Cancel before renewal |
| Free trial, cancelled | Trial until &lt;date&gt;, “You cancelled”, “Activate again” | Activate again |
| Paid active | Premium Active, “Cancel subscription” | Cancel subscription |
| Paid, cancelled by user | Active until &lt;date&gt;, “You cancelled”, “Activate again” | Activate again |
| Paid, autopay halted | Active until &lt;date&gt;, “Autopay cancelled”, “Activate again” | Activate again |
| No plan / period ended | No Active Plan, “Activate again” | Activate again |
