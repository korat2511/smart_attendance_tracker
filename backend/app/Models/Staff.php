<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Builder;

class Staff extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'phone_number',
        'salary_type',
        'salary_amount',
        'overtime_charges',
    ];

    protected $casts = [
        'salary_amount' => 'decimal:2',
        'overtime_charges' => 'decimal:2',
    ];

    /**
     * Boot the model and apply global scope for multi-tenancy
     */
    protected static function booted(): void
    {
        // Global scope ensures all queries are automatically scoped to the authenticated user
        // This prevents any accidental data leakage between business owners
        static::addGlobalScope('user', function (Builder $builder) {
            if (auth()->check()) {
                $builder->where('user_id', auth()->id());
            }
        });
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }
}
