<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Subscription extends Model
{
    protected $fillable = [
        'user_id',
        'razorpay_subscription_id',
        'razorpay_plan_id',
        'razorpay_customer_id',
        'status',
        'cancel_at_period_end',
        'trial_ends_at',
        'current_period_start',
        'current_period_end',
        'charge_at',
        'amount',
        'currency',
        'metadata',
    ];

    protected $casts = [
        'cancel_at_period_end' => 'boolean',
        'trial_ends_at' => 'datetime',
        'current_period_start' => 'datetime',
        'current_period_end' => 'datetime',
        'amount' => 'decimal:2',
        'metadata' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isActive(): bool
    {
        return in_array($this->status, ['active', 'authenticated']);
    }

    public function isTrialing(): bool
    {
        return $this->trial_ends_at && $this->trial_ends_at->isFuture();
    }

    public function hasValidAccess(): bool
    {
        return $this->isActive() || $this->isTrialing();
    }
}
