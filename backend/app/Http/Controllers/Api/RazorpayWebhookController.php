<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use App\Models\SubscriptionTrial;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class RazorpayWebhookController extends Controller
{
    public function handle(Request $request)
    {
        $payload = $request->all();
        $signature = $request->header('X-Razorpay-Signature');
        $webhookSecret = env('RAZORPAY_WEBHOOK_SECRET');

        if ($webhookSecret && $signature) {
            $expectedSignature = hash_hmac('sha256', $request->getContent(), $webhookSecret);
            if (!hash_equals($expectedSignature, $signature)) {
                Log::warning('Razorpay webhook signature verification failed');
                return response()->json(['error' => 'Invalid signature'], 400);
            }
        }

        $event = $payload['event'] ?? null;
        $entity = $payload['payload']['subscription']['entity'] ?? 
                  $payload['payload']['payment']['entity'] ?? null;

        Log::info('Razorpay webhook received', [
            'event' => $event,
            'entity_id' => $entity['id'] ?? null,
        ]);

        if (!$event || !$entity) {
            return response()->json(['status' => 'ignored']);
        }

        switch ($event) {
            case 'subscription.authenticated':
                $this->handleSubscriptionAuthenticated($entity);
                break;

            case 'subscription.activated':
                $this->handleSubscriptionActivated($entity);
                break;

            case 'subscription.charged':
                $this->handleSubscriptionCharged($entity);
                break;

            case 'subscription.pending':
                $this->handleSubscriptionPending($entity);
                break;

            case 'subscription.halted':
                $this->handleSubscriptionHalted($entity);
                break;

            case 'subscription.cancelled':
                $this->handleSubscriptionCancelled($entity);
                break;

            case 'subscription.completed':
                $this->handleSubscriptionCompleted($entity);
                break;

            case 'payment.captured':
                $this->handlePaymentCaptured($payload['payload']['payment']['entity'] ?? null);
                break;

            case 'payment.failed':
                $this->handlePaymentFailed($payload['payload']['payment']['entity'] ?? null);
                break;

            default:
                Log::info('Unhandled Razorpay webhook event', ['event' => $event]);
        }

        return response()->json(['status' => 'ok']);
    }

    private function handleSubscriptionAuthenticated(array $entity): void
    {
        $this->updateSubscription($entity, 'authenticated');
    }

    private function handleSubscriptionActivated(array $entity): void
    {
        $subscription = $this->updateSubscription($entity, 'active');

        if ($subscription) {
            $notes = $entity['notes'] ?? [];
            $mobile = $notes['mobile'] ?? null;

            if ($mobile && !SubscriptionTrial::hasUsedTrial($mobile)) {
                SubscriptionTrial::create([
                    'user_id' => $subscription->user_id,
                    'mobile' => $mobile,
                    'trial_used_at' => now(),
                ]);
                Log::info('Trial marked as used', ['mobile' => $mobile]);
            }
        }
    }

    private function handleSubscriptionCharged(array $entity): void
    {
        $subscription = $this->updateSubscription($entity, 'active');

        if ($subscription) {
            $currentEnd = isset($entity['current_end']) 
                ? \Carbon\Carbon::createFromTimestamp($entity['current_end']) 
                : null;

            $subscription->update([
                'current_period_end' => $currentEnd,
                'charge_at' => $entity['charge_at'] ?? null,
            ]);
        }
    }

    private function handleSubscriptionPending(array $entity): void
    {
        $this->updateSubscription($entity, 'pending');
    }

    private function handleSubscriptionHalted(array $entity): void
    {
        $this->updateSubscription($entity, 'halted');
    }

    private function handleSubscriptionCancelled(array $entity): void
    {
        $this->updateSubscription($entity, 'cancelled');
    }

    private function handleSubscriptionCompleted(array $entity): void
    {
        $this->updateSubscription($entity, 'completed');
    }

    private function handlePaymentCaptured(?array $entity): void
    {
        if (!$entity) return;

        Log::info('Payment captured', [
            'payment_id' => $entity['id'] ?? null,
            'amount' => $entity['amount'] ?? null,
        ]);
    }

    private function handlePaymentFailed(?array $entity): void
    {
        if (!$entity) return;

        Log::warning('Payment failed', [
            'payment_id' => $entity['id'] ?? null,
            'error' => $entity['error_description'] ?? null,
        ]);
    }

    private function updateSubscription(array $entity, string $status): ?Subscription
    {
        $subscriptionId = $entity['id'] ?? null;

        if (!$subscriptionId) {
            return null;
        }

        $subscription = Subscription::where('razorpay_subscription_id', $subscriptionId)->first();

        if (!$subscription) {
            Log::warning('Subscription not found for webhook', [
                'razorpay_subscription_id' => $subscriptionId,
            ]);
            return null;
        }

        $currentStart = isset($entity['current_start']) 
            ? \Carbon\Carbon::createFromTimestamp($entity['current_start']) 
            : null;
        $currentEnd = isset($entity['current_end']) 
            ? \Carbon\Carbon::createFromTimestamp($entity['current_end']) 
            : null;

        $data = [
            'status' => $status,
            'current_period_start' => $currentStart,
            'current_period_end' => $currentEnd,
            'charge_at' => $entity['charge_at'] ?? null,
            'metadata' => array_merge($subscription->metadata ?? [], [
                'last_webhook_event' => $status,
                'last_webhook_at' => now()->toIso8601String(),
            ]),
        ];
        if ($status === 'cancelled') {
            $data['cancel_at_period_end'] = false;
        }
        $subscription->update($data);

        Log::info('Subscription updated via webhook', [
            'subscription_id' => $subscription->id,
            'status' => $status,
        ]);

        return $subscription;
    }
}
