<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SubscriptionTrial extends Model
{
    protected $fillable = [
        'user_id',
        'mobile',
        'trial_used_at',
    ];

    protected $casts = [
        'trial_used_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function hasUsedTrial(string $mobile): bool
    {
        return self::where('mobile', $mobile)->exists();
    }
}
