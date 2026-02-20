<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Staff;
use App\Models\Attendance;
use App\Models\CashbookIncome;
use App\Models\CashbookExpense;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register a new user (Signup)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function signup(Request $request)
    {
        // Validate the request
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'mobile' => 'required|string|max:20|unique:users',
            'business_name' => 'required|string|max:255',
            'staff_size' => 'required|integer|min:0',
            'password' => 'required|string|min:8',
        ]);

        // Create the user
        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'mobile' => $validated['mobile'],
            'business_name' => $validated['business_name'],
            'staff_size' => $validated['staff_size'],
            'password' => Hash::make($validated['password']),
        ]);

        // Create API token
        $token = $user->createToken('auth_token')->plainTextToken;

        // Return success response
        return response()->json([
            'success' => true,
            'message' => 'User registered successfully',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'mobile' => $user->mobile,
                    'business_name' => $user->business_name,
                    'staff_size' => $user->staff_size,
                ],
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 201);
    }

    /**
     * Login user
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request)
    {
        // Validate the request
        $request->validate([
            'mobile' => 'required|string',
            'password' => 'required|string',
        ]);

        // Find user by mobile
        $user = User::where('mobile', $request->mobile)->first();

        // Check if user exists and password is correct
        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'mobile' => ['The provided credentials are incorrect.'],
            ]);
        }

        // Delete existing tokens (optional - for single device login)
        // $user->tokens()->delete();

        // Create new API token
        $token = $user->createToken('auth_token')->plainTextToken;

        // Return success response
        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'mobile' => $user->mobile,
                    'business_name' => $user->business_name,
                    'staff_size' => $user->staff_size,
                ],
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 200);
    }

    /**
     * Logout user (revoke current token)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout(Request $request)
    {
        // Revoke the token that was used to authenticate the current request
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ], 200);
    }

    /**
     * Get authenticated user
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $request->user()->id,
                    'name' => $request->user()->name,
                    'email' => $request->user()->email,
                    'mobile' => $request->user()->mobile,
                    'business_name' => $request->user()->business_name,
                    'staff_size' => $request->user()->staff_size,
                ],
            ],
        ], 200);
    }

    /**
     * Delete user account and all associated data
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function deleteAccount(Request $request)
    {
        $user = $request->user();

        try {
            DB::beginTransaction();

            // Cancel any active Razorpay subscription
            $activeSubscription = Subscription::where('user_id', $user->id)
                ->whereIn('status', ['active', 'authenticated', 'pending'])
                ->first();

            if ($activeSubscription && $activeSubscription->razorpay_subscription_id) {
                try {
                    $keyId = config('services.razorpay.key_id');
                    $keySecret = config('services.razorpay.key_secret');

                    Http::withBasicAuth($keyId, $keySecret)
                        ->post("https://api.razorpay.com/v1/subscriptions/{$activeSubscription->razorpay_subscription_id}/cancel", [
                            'cancel_at_cycle_end' => 0,
                        ]);
                } catch (\Exception $e) {
                    Log::warning('Failed to cancel Razorpay subscription during account deletion', [
                        'user_id' => $user->id,
                        'subscription_id' => $activeSubscription->razorpay_subscription_id,
                        'error' => $e->getMessage(),
                    ]);
                }
            }

            // Get all staff IDs for this user
            $staffIds = Staff::withoutGlobalScopes()->where('user_id', $user->id)->pluck('id');

            // Delete attendance records for all staff
            Attendance::withoutGlobalScopes()->whereIn('staff_id', $staffIds)->delete();

            // Delete all staff
            Staff::withoutGlobalScopes()->where('user_id', $user->id)->delete();

            // Delete cashbook entries
            CashbookIncome::withoutGlobalScopes()->where('user_id', $user->id)->delete();
            CashbookExpense::withoutGlobalScopes()->where('user_id', $user->id)->delete();

            // Delete subscriptions
            Subscription::where('user_id', $user->id)->delete();

            // Revoke all tokens
            $user->tokens()->delete();

            // Delete the user
            $user->delete();

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Account deleted successfully.',
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();

            Log::error('Account deletion failed', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete account. Please try again.',
            ], 500);
        }
    }
}
