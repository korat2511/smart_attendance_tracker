<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use App\Models\SubscriptionTrial;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SubscriptionController extends Controller
{
    private string $keyId;
    private string $keySecret;
    private string $planId;
    private string $baseUrl = 'https://api.razorpay.com/v1';

    public function __construct()
    {
        $this->keyId = config('services.razorpay.key_id', env('RAZORPAY_KEY_ID'));
        $this->keySecret = config('services.razorpay.key_secret', env('RAZORPAY_KEY_SECRET'));
        $this->planId = config('services.razorpay.plan_id', env('RAZORPAY_PLAN_ID'));
    }

    public function getStatus(Request $request)
    {
        $user = $request->user();
        
        $subscription = Subscription::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$subscription) {
            return response()->json([
                'has_active_plan' => false,
                'has_free_trial' => false,
                'trial_ends_at' => null,
                'subscription_status' => null,
                'can_use_trial' => !SubscriptionTrial::hasUsedTrial($user->mobile),
            ]);
        }

        $isTrialing = $subscription->isTrialing();
        $isActive = $subscription->isActive();

        return response()->json([
            'has_active_plan' => $isActive && !$isTrialing,
            'has_free_trial' => $isTrialing,
            'trial_ends_at' => $subscription->trial_ends_at?->toIso8601String(),
            'subscription_status' => $subscription->status,
            'current_period_end' => $subscription->current_period_end?->toIso8601String(),
            'can_use_trial' => !SubscriptionTrial::hasUsedTrial($user->mobile),
        ]);
    }

    public function create(Request $request)
    {
        $user = $request->user();
        $mobile = $user->mobile;

        $existingActive = Subscription::where('user_id', $user->id)
            ->whereIn('status', ['active', 'authenticated', 'pending'])
            ->first();

        if ($existingActive) {
            return response()->json([
                'error' => 'You already have an active subscription.',
            ], 400);
        }

        $canUseTrial = !SubscriptionTrial::hasUsedTrial($mobile);

        try {
            $customerId = $this->getOrCreateCustomer($user);

            $subscriptionData = [
                'plan_id' => $this->planId,
                'customer_id' => $customerId,
                'total_count' => 120,
                'quantity' => 1,
                'customer_notify' => 1,
                'notes' => [
                    'user_id' => (string) $user->id,
                    'mobile' => $mobile,
                ],
            ];

            if ($canUseTrial) {
                $trialEndTimestamp = now()->addDays(7)->timestamp;
                $subscriptionData['start_at'] = $trialEndTimestamp;
                $subscriptionData['addons'] = [
                    [
                        'item' => [
                            'name' => 'Setup Fee',
                            'amount' => 1000,
                            'currency' => 'INR',
                        ],
                    ],
                ];
            }

            $response = Http::withBasicAuth($this->keyId, $this->keySecret)
                ->post("{$this->baseUrl}/subscriptions", $subscriptionData);

            if (!$response->successful()) {
                Log::error('Razorpay subscription creation failed', [
                    'response' => $response->json(),
                    'user_id' => $user->id,
                ]);
                return response()->json([
                    'error' => 'Failed to create subscription. Please try again.',
                ], 500);
            }

            $razorpaySubscription = $response->json();

            $subscription = Subscription::create([
                'user_id' => $user->id,
                'razorpay_subscription_id' => $razorpaySubscription['id'],
                'razorpay_plan_id' => $this->planId,
                'razorpay_customer_id' => $customerId,
                'status' => $razorpaySubscription['status'],
                'trial_ends_at' => $canUseTrial ? now()->addDays(7) : null,
                'amount' => 199.00,
                'currency' => 'INR',
                'metadata' => $razorpaySubscription,
            ]);

            return response()->json([
                'subscription_id' => $razorpaySubscription['id'],
                'short_url' => $razorpaySubscription['short_url'] ?? null,
                'status' => $razorpaySubscription['status'],
                'has_trial' => $canUseTrial,
                'razorpay_key' => $this->keyId,
            ]);

        } catch (\Exception $e) {
            Log::error('Subscription creation error', [
                'error' => $e->getMessage(),
                'user_id' => $user->id,
            ]);
            return response()->json([
                'error' => 'An error occurred. Please try again.',
            ], 500);
        }
    }

    private function getOrCreateCustomer($user): string
    {
        $existingSubscription = Subscription::where('user_id', $user->id)
            ->whereNotNull('razorpay_customer_id')
            ->first();

        if ($existingSubscription) {
            return $existingSubscription->razorpay_customer_id;
        }

        $response = Http::withBasicAuth($this->keyId, $this->keySecret)
            ->post("{$this->baseUrl}/customers", [
                'name' => $user->name,
                'email' => $user->email ?? "{$user->mobile}@placeholder.com",
                'contact' => $user->mobile,
                'notes' => [
                    'user_id' => (string) $user->id,
                ],
            ]);

        if ($response->successful()) {
            return $response->json()['id'];
        }

        $errorData = $response->json();
        if (isset($errorData['error']['description']) && 
            str_contains($errorData['error']['description'], 'Customer already exists')) {
            
            $searchResponse = Http::withBasicAuth($this->keyId, $this->keySecret)
                ->get("{$this->baseUrl}/customers", [
                    'contact' => $user->mobile,
                ]);

            if ($searchResponse->successful()) {
                $customers = $searchResponse->json()['items'] ?? [];
                if (!empty($customers)) {
                    return $customers[0]['id'];
                }
            }
        }

        throw new \Exception('Failed to create Razorpay customer: ' . $response->body());
    }

    public function cancel(Request $request)
    {
        $user = $request->user();

        $subscription = Subscription::where('user_id', $user->id)
            ->whereIn('status', ['active', 'authenticated', 'pending'])
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$subscription) {
            return response()->json([
                'error' => 'No active subscription found.',
            ], 404);
        }

        try {
            $response = Http::withBasicAuth($this->keyId, $this->keySecret)
                ->post("{$this->baseUrl}/subscriptions/{$subscription->razorpay_subscription_id}/cancel", [
                    'cancel_at_cycle_end' => 1,
                ]);

            if (!$response->successful()) {
                Log::error('Razorpay subscription cancellation failed', [
                    'response' => $response->json(),
                    'subscription_id' => $subscription->razorpay_subscription_id,
                ]);
                return response()->json([
                    'error' => 'Failed to cancel subscription. Please try again.',
                ], 500);
            }

            $subscription->update([
                'status' => 'cancelled',
                'metadata' => array_merge($subscription->metadata ?? [], [
                    'cancelled_at' => now()->toIso8601String(),
                ]),
            ]);

            return response()->json([
                'message' => 'Subscription will be cancelled at the end of the current billing period.',
                'current_period_end' => $subscription->current_period_end?->toIso8601String(),
            ]);

        } catch (\Exception $e) {
            Log::error('Subscription cancellation error', [
                'error' => $e->getMessage(),
                'subscription_id' => $subscription->razorpay_subscription_id,
            ]);
            return response()->json([
                'error' => 'An error occurred. Please try again.',
            ], 500);
        }
    }
}
