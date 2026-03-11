# Stripe Webhook Debugging — March 11, 2026

## Problem

Stripe disabled the webhook endpoint `https://app.cursuriromana.ro/payment/gateway/stripe/webhook.php` due to repeated 400 errors. All `customer.subscription.updated` events were failing. The first warning email from Stripe arrived on March 4, 2026.

## Investigation

### What we checked

1. **Webhook signing secret** — The secret in the DB (`whsec_hdhfFzzHruD9Gz55va0GHVVh4bJz5MXc`) matched the Stripe dashboard. Not the issue.
2. **Server clock** — UTC time was correct. Not the issue.
3. **Stripe API version** — Event used `2025-06-30.basil`. No recent Moodle or plugin updates were made.

### Root cause: Webhook/payment account mismatch

The Moodle Stripe plugin creates one webhook endpoint per payment account. This resulted in:

- **4 webhook endpoints** in Stripe (all pointing to the same URL)
- **4 rows** in `mdlmn_paygw_stripe_webhooks` for payment accounts 3, 4, 5, 6

However, the **active payment accounts** in Moodle are **1 and 2**:

| id | name              | enabled | archived |
|----|-------------------|---------|----------|
| 1  | Stripe Monthly    | 1       | 0        |
| 2  | Stripe 6 Months   | 1       | 0        |
| 3  | Stripe Lunar      | 0       | 1        |
| 4  | Stripe 6 luni     | 0       | 1        |
| 5  | Stripe 3 luni     | 0       | 1        |
| 6  | Stripe anual      | 0       | 1        |

**Accounts 3–6 are archived**, yet their webhooks were the only ones registered. The active accounts (1, 2) had **no webhooks**.

### Why events returned 400

When Stripe sends a `customer.subscription.updated` event:

1. The plugin uses the subscription metadata (`itemid`, `component`, `paymentarea`) to resolve the payment account
2. The metadata resolves to account 1 or 2 (active accounts)
3. The plugin looks up the webhook secret for that account — but no webhook exists for accounts 1 or 2
4. Signature verification fails → HTTP 400

### Affected subscription

- **User**: Reka Ciocanelli (Moodle user 114, `filipok`)
- **Subscription**: `sub_1S7uA6AmN3QVbd6g95zaLOmy`
- **Product**: Enrolment in course Gramatica limbii romane — 6 luni
- **Price**: 150 RON every 6 months (`price_1Q0Sx9AmN3QVbd6gwHt6MROg`)
- **Status in Moodle DB**: `active` (no action needed)
- **Billing period**: Mar 1 – Sep 1, 2026

## Fix — Step by step

### Step 1: Delete old webhook endpoints from Stripe

Go to [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks) and delete all 4 webhook endpoints (use the `...` menu on each row → Delete).

### Step 2: Clean the database

```sql
DELETE FROM mdlmn_paygw_stripe_webhooks;
```

Verify:

```sql
SELECT * FROM mdlmn_paygw_stripe_webhooks;
-- Should return 0 rows
```

### Step 3: Re-create webhooks for active accounts

In Moodle admin:

1. Go to **Site administration → General → Payment accounts**
2. Open **"Stripe Monthly"** → click the Stripe gateway settings → click **Save**
3. Open **"Stripe 6 Months"** → click the Stripe gateway settings → click **Save**

This triggers the plugin to create new webhook endpoints for accounts 1 and 2.

### Step 4: Verify

**Database:**

```sql
SELECT * FROM mdlmn_paygw_stripe_webhooks;
-- Should show 2 rows for payment accounts 1 and 2
```

**Stripe Dashboard:**

- 2 new **Active** webhook endpoints should appear
- The secrets should match between Stripe and the DB

### Step 5: Test

From the Stripe dashboard, open one of the new webhook endpoints and use "Send test webhook" to confirm it returns HTTP 200.
