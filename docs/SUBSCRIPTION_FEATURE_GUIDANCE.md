# Subscription Feature – Implementation Guidance (India)

This document gives **guidance only** (no code). Use it when you implement: **₹10 upfront + 7-day free trial + ₹199/month autopay**, India-only, with multiple UPI options and one-time free trial per mobile.

---

## 1. Recommended Gateway & Packages

### Primary choice: **Razorpay**

- **Subscriptions API** – Plans, free trial (`start_at`), upfront amount (`addons`), recurring billing.
- **UPI AutoPay** – Recurring via UPI (Paytm, PhonePe, Google Pay, BHIM, etc.). Limit ₹15,000/transaction; ₹199/month is within limit.
- **Flutter SDK** – `razorpay_flutter` (pub.dev) for checkout; supports UPI and other methods.
- **Backend** – REST API from Laravel/PHP (no official Laravel package required; use `guzzlehttp/guzzle` or similar).

**Why Razorpay:**  
Supports Plan + Subscription + free trial + upfront amount + UPI AutoPay + multiple UPI apps in one flow. Widely used in India and well documented.

**Alternatives (if needed):**

- **Cashfree** – Subscriptions + Flutter SDK; multiple UPI options.
- **PhonePe PG** – Autopay/subscription API; more suited if you want PhonePe-first.

---

## 2. High-Level Flow

### 2.1 Pricing model (your requirement)

| Item              | Value        | How in Razorpay                          |
|-------------------|-------------|------------------------------------------|
| First payment     | ₹10         | **Upfront amount** (addon) at subscribe  |
| Free trial        | 7 days      | **Trial** via `start_at` = today + 7 days |
| Recurring         | ₹199/month  | **Plan** amount, period = monthly       |
| Autopay           | Yes         | **UPI AutoPay** (mandate during first ₹10) |

- User pays **₹10 once** → you create subscription with **7-day trial** and **₹199/month** plan.
- After 7 days, Razorpay charges **₹199** automatically each month (autopay) if UPI mandate was approved.

### 2.2 One-time free trial per mobile

- **Your backend** must enforce “one free trial per mobile number”.
- Razorpay does **not** enforce this; it only manages plans/subscriptions.
- **Implementation idea:**
  - Table, e.g. `subscription_trials`: `user_id`, `mobile`, `trial_used_at`, etc.
  - When user tries to start a subscription:
    - If `mobile` already has a row in `subscription_trials` → do **not** create a subscription with trial; either show “trial already used” or offer **paid-only** (no trial) subscription.
    - If `mobile` has never used trial → allow subscription with trial (₹10 + 7-day trial + ₹199/month); after successful first payment, insert into `subscription_trials`.

### 2.3 After login / signup – where to send user

- **Backend:**  
  For the logged-in user, determine:
  - Has **active paid plan** (subscription status from Razorpay or your DB), **or**
  - Has **active free trial** (e.g. `trial_ends_at > now()` and subscription in trial state).
- **API:**  
  e.g. `GET /api/v1/me` or `GET /api/v1/subscription/status` returning:
  - `has_active_plan: boolean`
  - `has_free_trial: boolean`
  - `trial_ends_at: date|null`
  - `subscription_status: string` (e.g. active, trialing, past_due, cancelled)
- **App (Flutter):**
  - If `has_active_plan` **or** (`has_free_trial` and trial not expired) → **navigate to Home**.
  - Else → **show Subscription / Paywall screen** (e.g. “Unlock all features”, ₹10 + 7-day trial + ₹199/month, “Start now”).

---

## 3. Backend (Laravel) – What to Do

1. **Razorpay keys**  
   Store `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in `.env`. Use test keys for dev.

2. **Plans**  
   Create **one Plan** in Razorpay (Dashboard or API):  
   - Amount: **19900** (paise, i.e. ₹199),  
   - Period: **monthly**,  
   - Currency: **INR**.  
   Save `plan_id` (e.g. `plan_xxxxx`) in config or DB.

3. **Subscription creation (when user taps “Start now”)**  
   - Ensure **one-time trial per mobile** (check your `subscription_trials` or equivalent).
   - If trial allowed:  
     - Call Razorpay **Create Subscription** with:
       - `plan_id` = your ₹199/month plan,
       - `customer_id` = Razorpay customer (create if needed),
       - `start_at` = **current time + 7 days** (Unix timestamp),
       - `addons` = one-time **upfront amount ₹10** (in paise: 1000).
     - Razorpay returns a **subscription_id** and often a **short_url** or payment link.
   - If trial not allowed (same mobile already used trial):  
     - Create subscription **without** trial (e.g. `start_at` = now and no trial), or show a different flow (e.g. “Subscribe for ₹199/month only”).

4. **First payment (₹10)**  
   - User completes payment (UPI / card / etc.) in Razorpay Checkout (opened from Flutter via SDK or WebView).
   - Razorpay sends **webhook** (e.g. `subscription.activated` or payment success).  
   - Backend:
     - Marks subscription as “trialing” or “active” and stores `trial_ends_at`, `subscription_id`, etc.
     - Records “trial used” for this `mobile` in `subscription_trials`.

5. **Webhooks**  
   - Subscribe to Razorpay webhooks: `subscription.activated`, `subscription.charged`, `subscription.cancelled`, `payment.captured`, etc.
   - Use them to update your DB (subscription status, next billing date, etc.) and to revoke access when subscription ends or fails.

6. **APIs you need**  
   - **Subscription status for current user**  
     `GET /api/v1/subscription/status` (or include in `GET /me`):  
     Return `has_active_plan`, `has_free_trial`, `trial_ends_at`, `subscription_status` so the app can decide Home vs Paywall.
   - **Create subscription / get payment link**  
     `POST /api/v1/subscription/create` (or similar):  
     Input: optional `mobile` for trial check.  
     Output: Razorpay subscription id + **payment link** or **order_id** for Flutter to open checkout.

7. **DB (suggested)**  
   - `subscriptions`: user_id, razorpay_subscription_id, razorpay_plan_id, status, trial_ends_at, current_end_at, etc.
   - `subscription_trials`: user_id or mobile, trial_used_at (to enforce one-time trial per mobile).

---

## 4. Flutter App – What to Do

1. **Add SDK**  
   - `razorpay_flutter` (see [Razorpay Flutter docs](https://razorpay.com/docs/payments/payment-gateway/flutter-integration/standard/)).

2. **After login/signup**  
   - Call your API (e.g. `GET /me` or `GET /subscription/status`).
   - If `has_active_plan` or (has_free_trial and trial not expired) → **go to Home**.
   - Else → **go to Subscription/Paywall screen**.

3. **Paywall / Subscription screen (like your reference)**  
   - Show: “Unlock all features for”, “₹199” (monthly), “₹10 + 7-day free trial”, “Autopay starts after free trial, cancel anytime”.
   - “Pay via” → dropdown: **multiple options** (Paytm, PhonePe, Google Pay, BHIM, Cards, etc.).  
   - Razorpay Checkout already supports these; you don’t need to implement each gateway.  
   - “Start now” → call your backend to create subscription (with trial if allowed); open Razorpay Checkout with the returned payment link or order details.

4. **Razorpay Checkout**  
   - Open Razorpay’s hosted checkout (or use SDK’s native flow) with the subscription payment link / order id.  
   - User selects UPI app (Paytm, PhonePe, Google Pay, BHIM, etc.) and completes **first payment (₹10)** and **UPI AutoPay mandate** in one flow.  
   - On success/failure, Razorpay redirects or callbacks; your app then checks subscription status and navigates to Home or shows error.

5. **UPI AutoPay**  
   - Handled by Razorpay during first payment (mandate approval). No extra “only Paytm” logic; Razorpay shows all supported UPI apps.  
   - Recurring ₹199/month is then charged automatically by Razorpay as per mandate.

---

## 5. Flow Summary

```
Signup/Login
    → API: subscription/status (or /me)
    → If active plan or active trial → Home
    → Else → Paywall

Paywall
    → “Start now” → API: subscription/create (backend checks one-time trial by mobile)
    → Backend: create Razorpay subscription (₹10 upfront + 7-day trial + ₹199/month)
    → App: open Razorpay Checkout (user picks Paytm/PhonePe/GPay/BHIM/Card etc.)
    → User pays ₹10 and approves UPI AutoPay
    → Webhook: subscription.activated etc. → Backend updates DB, marks trial used for mobile
    → App: on success → refresh status → go to Home
```

---

## 6. Important Points

- **One-time trial per mobile** – Implement only in your backend (e.g. `subscription_trials` + check before creating subscription with trial).
- **Multiple payment options** – Use Razorpay’s single integration; they show Paytm, PhonePe, Google Pay, BHIM, cards, etc. No need for separate Paytm-only integration.
- **₹10 + 7-day trial + ₹199/month** – Map to: **upfront addon ₹10** + **start_at = now + 7 days** + **plan ₹199 monthly**.
- **Autopay** – User sets it while paying ₹10 (UPI AutoPay mandate). Razorpay then charges ₹199/month automatically.
- **India-only** – Use INR, Razorpay India keys, and UPI AutoPay; no change needed for “India-only” except not offering non-India payment methods if you want.

When you are ready to implement, you can use this doc as a checklist for backend APIs, DB, Flutter screens, and Razorpay Dashboard (plan, webhooks, test keys).
